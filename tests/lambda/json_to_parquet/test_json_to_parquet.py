"""
Tests for terraform/lambda/scripts/json_to_parquet/lambda_function.py
"""
from unittest.mock import patch

import pandas as pd
import pytest


# ── Pure functions ────────────────────────────────────────────────────────

def test_normalize_json_to_df_flattens_nested_items(json_to_parquet_module):
    raw = {"items": [{"id": "10", "snippet": {"title": "Music"}}]}
    df = json_to_parquet_module.normalize_json_to_df(raw)

    assert "snippet.title" in df.columns  # dotted, pre-sanitize
    assert df.iloc[0]["snippet.title"] == "Music"


def test_sanitize_column_names_flattens_dots(json_to_parquet_module):
    df = pd.DataFrame({"id": ["10"], "snippet.title": ["Music"]})
    df = json_to_parquet_module.sanitize_column_names(df)

    assert "snippet_title" in df.columns
    assert "snippet.title" not in df.columns


def test_validate_category_data_dedupes_on_id(json_to_parquet_module):
    df = pd.DataFrame({
        "id": ["10", "17", "17"],
        "snippet_title": ["Music", "Sports", "Sports"],
    })
    result = json_to_parquet_module.validate_category_data(df)

    assert len(result) == 2


def test_validate_category_data_raises_on_empty(json_to_parquet_module):
    with pytest.raises(ValueError, match="Empty DataFrame"):
        json_to_parquet_module.validate_category_data(pd.DataFrame())


def test_extract_region_parses_partition(json_to_parquet_module):
    key = "youtube/raw_statistics/region=gb/date=2026-07-17/hour=03/x.json"
    assert json_to_parquet_module.extract_region(key) == "gb"


def test_extract_region_defaults_to_unknown(json_to_parquet_module):
    assert json_to_parquet_module.extract_region("youtube/no-region-here/x.json") == "unknown"


def test_extract_s3_records_url_decodes_key(json_to_parquet_module):
    event = {"Records": [{"s3": {"bucket": {"name": "b"}, "object": {"key": "a%20b.json"}}}]}
    assert json_to_parquet_module.extract_s3_records(event) == [("b", "a b.json")]


def test_extract_s3_records_empty_for_step_functions_payload(json_to_parquet_module):
    """Documents the exact shape of the bug found in review: a Step
    Functions-style payload has no S3 Records, so this always returns []."""
    assert json_to_parquet_module.extract_s3_records({"triggered_by": "step_functions"}) == []


# ── discover_reference_keys (the fix) ─────────────────────────────────────

class _FakePaginator:
    def __init__(self, pages):
        self._pages = pages

    def paginate(self, Bucket, Prefix):
        yield from self._pages


class _FakeS3:
    def __init__(self, pages):
        self._pages = pages

    def get_paginator(self, name):
        assert name == "list_objects_v2"
        return _FakePaginator(self._pages)


def test_discover_reference_keys_filters_by_date_partition(json_to_parquet_module):
    pages = [
        {"Contents": [
            {"Key": "youtube/raw_statistics_reference_data/region=us/date=2026-07-17/us_category_id.json"},
            {"Key": "youtube/raw_statistics_reference_data/region=gb/date=2026-07-16/gb_category_id.json"},
        ]},
        {"Contents": [
            {"Key": "youtube/raw_statistics_reference_data/region=in/date=2026-07-17/in_category_id.json"},
        ]},
    ]
    fake_s3 = _FakeS3(pages)

    keys = json_to_parquet_module.discover_reference_keys(fake_s3, "my-bronze-bucket", "2026-07-17")

    assert len(keys) == 2
    assert all(bucket == "my-bronze-bucket" for bucket, _ in keys)
    assert all("date=2026-07-17" in key for _, key in keys)


def test_discover_reference_keys_empty_when_nothing_matches(json_to_parquet_module):
    fake_s3 = _FakeS3([{"Contents": []}])
    keys = json_to_parquet_module.discover_reference_keys(fake_s3, "bucket", "2026-07-17")
    assert keys == []


# ── Handler-level behavior (the bug + fix) ────────────────────────────────

def test_lambda_handler_uses_discovery_when_invoked_by_step_functions(
    json_to_parquet_module, monkeypatch
):
    """Before this fix, a Step Functions invocation (no S3 Records in the
    event) silently processed zero files on every run — this is the
    regression test for that."""
    monkeypatch.setenv("S3_BUCKET_BRONZE", "my-bronze-bucket")

    fake_records = [("my-bronze-bucket", "youtube/raw_statistics_reference_data/region=us/date=2026-07-17/us_category_id.json")]

    with patch.object(
        json_to_parquet_module, "discover_reference_keys", return_value=fake_records
    ) as mock_discover, patch.object(
        json_to_parquet_module, "read_json_from_s3",
        return_value={"items": [{"id": "10", "snippet": {"title": "Music"}}]},
    ), patch.object(json_to_parquet_module, "write_to_silver", return_value="s3://fake/"):
        result = json_to_parquet_module.lambda_handler(
            {"triggered_by": "step_functions", "date_partition": "2026-07-17"}, None
        )

    mock_discover.assert_called_once()
    assert len(result["processed"]) == 1
    assert result["errors"] == []


def test_lambda_handler_raises_when_date_partition_missing(json_to_parquet_module):
    with pytest.raises(ValueError, match="date_partition missing"):
        json_to_parquet_module.lambda_handler({"triggered_by": "step_functions"}, None)


def test_lambda_handler_raises_when_no_reference_files_found(
    json_to_parquet_module, monkeypatch
):
    monkeypatch.setenv("S3_BUCKET_BRONZE", "my-bronze-bucket")

    with patch.object(json_to_parquet_module, "discover_reference_keys", return_value=[]):
        with pytest.raises(RuntimeError, match="No reference-category files found"):
            json_to_parquet_module.lambda_handler(
                {"triggered_by": "step_functions", "date_partition": "2026-07-17"}, None
            )


def test_lambda_handler_raises_when_all_discovered_records_fail(
    json_to_parquet_module, monkeypatch
):
    monkeypatch.setenv("S3_BUCKET_BRONZE", "my-bronze-bucket")
    fake_records = [("my-bronze-bucket", "some/key.json")]

    with patch.object(
        json_to_parquet_module, "discover_reference_keys", return_value=fake_records
    ), patch.object(
        json_to_parquet_module, "read_json_from_s3", side_effect=Exception("boom")
    ), patch.object(json_to_parquet_module, "send_alert"):
        with pytest.raises(RuntimeError, match="failed to process"):
            json_to_parquet_module.lambda_handler(
                {"triggered_by": "step_functions", "date_partition": "2026-07-17"}, None
            )
