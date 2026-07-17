"""
Tests for terraform/lambda/scripts/youtube_api_integration/lambda_function.py
"""
from datetime import datetime, timezone
from unittest.mock import patch

import pytest


# ── Pure functions ────────────────────────────────────────────────────────

def test_build_api_url_encodes_params(youtube_ingestion):
    url = youtube_ingestion.build_api_url(
        "https://www.googleapis.com/youtube/v3", "videos", {"a": "1", "b": "2"}
    )
    assert url == "https://www.googleapis.com/youtube/v3/videos?a=1&b=2"


def test_generate_s3_keys_trending_path(youtube_ingestion):
    now = datetime(2026, 7, 17, 3, 0, 0, tzinfo=timezone.utc)
    keys = youtube_ingestion.generate_s3_keys("us", now, "20260717_030000")

    assert keys["trending"] == (
        "youtube/raw_statistics/region=us/date=2026-07-17/hour=03/20260717_030000.json"
    )


def test_generate_s3_keys_categories_path(youtube_ingestion):
    now = datetime(2026, 7, 17, 3, 0, 0, tzinfo=timezone.utc)
    keys = youtube_ingestion.generate_s3_keys("us", now, "20260717_030000")

    assert keys["categories"] == (
        "youtube/raw_statistics_reference_data/region=us/date=2026-07-17/us_category_id.json"
    )


def test_enrich_with_metadata_counts_items(youtube_ingestion):
    now = datetime(2026, 7, 17, 3, 0, 0, tzinfo=timezone.utc)
    enriched = youtube_ingestion.enrich_with_metadata(
        {"items": [1, 2, 3]}, "ing1", "us", now
    )

    assert enriched["_pipeline_metadata"]["item_count"] == 3
    assert enriched["_pipeline_metadata"]["region"] == "us"
    assert enriched["_pipeline_metadata"]["ingestion_id"] == "ing1"


def test_enrich_with_metadata_handles_no_items_key(youtube_ingestion):
    now = datetime(2026, 7, 17, 3, 0, 0, tzinfo=timezone.utc)
    enriched = youtube_ingestion.enrich_with_metadata({}, "ing1", "us", now)

    assert "item_count" not in enriched["_pipeline_metadata"]


# ── Handler-level behavior ────────────────────────────────────────────────
#
# These cover the bug found in review: per-region failures were caught and
# swallowed internally, so the Lambda always returned normally (statusCode
# 200) even when every region failed — meaning Step Functions' Retry/Catch
# could never detect a total ingestion failure. lambda_handler now raises
# when zero regions succeed.

def test_lambda_handler_raises_when_all_regions_fail(youtube_ingestion, monkeypatch):
    monkeypatch.setenv("YOUTUBE_REGIONS", "US,GB")

    with patch.object(
        youtube_ingestion, "fetch_json_from_api", side_effect=Exception("API key revoked")
    ), patch.object(youtube_ingestion, "write_to_s3"), patch.object(
        youtube_ingestion, "send_alert"
    ) as mock_alert:
        with pytest.raises(RuntimeError, match="failed for ALL"):
            youtube_ingestion.lambda_handler({}, None)

        assert mock_alert.called


def test_lambda_handler_returns_200_on_partial_failure(youtube_ingestion, monkeypatch):
    monkeypatch.setenv("YOUTUBE_REGIONS", "US,GB")

    call_count = {"n": 0}

    def flaky_fetch(url):
        # Fail every call for GB, succeed for US, for both trending + categories.
        call_count["n"] += 1
        if "regionCode=gb" in url:
            raise Exception("region unavailable")
        return {"items": [{"id": "1"}]}

    with patch.object(youtube_ingestion, "fetch_json_from_api", side_effect=flaky_fetch), \
         patch.object(youtube_ingestion, "write_to_s3"), \
         patch.object(youtube_ingestion, "send_alert") as mock_alert:
        result = youtube_ingestion.lambda_handler({}, None)

    assert result["statusCode"] == 200
    assert "us" in result["results"]["success"]
    assert mock_alert.called  # partial-failure alert still fires


def test_lambda_handler_includes_date_partition_for_downstream_discovery(
    youtube_ingestion, monkeypatch
):
    """The Step Functions definition passes this value on to json_to_parquet
    so it can discover the files this run wrote — regressing this field
    silently breaks the reference-data pipeline."""
    monkeypatch.setenv("YOUTUBE_REGIONS", "US")

    with patch.object(
        youtube_ingestion, "fetch_json_from_api", return_value={"items": []}
    ), patch.object(youtube_ingestion, "write_to_s3"), patch.object(
        youtube_ingestion, "send_alert"
    ):
        result = youtube_ingestion.lambda_handler({}, None)

    assert "date_partition" in result
    datetime.strptime(result["date_partition"], "%Y-%m-%d")  # raises if malformed
