"""
Tests for terraform/lambda/scripts/data_quality_check/lambda_function.py
"""
import json

import pandas as pd
import pytest


@pytest.fixture
def clean_df():
    return pd.DataFrame({
        "video_id": ["a", "b", "c"] * 5,
        "title": ["t"] * 15,
        "channel_title": ["c"] * 15,
        "views": [100, 200, 300] * 5,
        "region": ["us"] * 15,
    })


def test_check_row_count_passes_above_minimum(data_quality_check_module, clean_df):
    result = data_quality_check_module.check_row_count(clean_df, "clean_statistics", min_count=10)
    assert result["passed"] is True


def test_check_row_count_fails_below_minimum(data_quality_check_module, clean_df):
    result = data_quality_check_module.check_row_count(clean_df, "clean_statistics", min_count=100)
    assert result["passed"] is False


def test_check_null_percentage_all_pass_on_clean_data(data_quality_check_module, clean_df):
    results = data_quality_check_module.check_null_percentage(clean_df, "clean_statistics", max_null_pct=5.0)
    assert all(r["passed"] for r in results)


def test_check_null_percentage_fails_above_threshold(data_quality_check_module, clean_df):
    df = clean_df.copy()
    df.loc[0:5, "title"] = None  # 6/15 = 40% nulls

    results = data_quality_check_module.check_null_percentage(df, "clean_statistics", max_null_pct=5.0)
    title_check = next(r for r in results if r["column"] == "title")

    assert title_check["passed"] is False
    assert title_check["value"] == pytest.approx(40.0, rel=0.01)


def test_check_null_percentage_result_is_json_safe(data_quality_check_module, clean_df):
    """Regression test: passed/value used to be numpy types, which
    json.dumps(..., default=str) would silently turn into strings —
    e.g. a failed check's `passed` becoming the string "False", which is
    truthy in both Python and JS. Every field must round-trip through
    plain json.dumps (no default= fallback) unchanged."""
    df = clean_df.copy()
    df.loc[0:5, "title"] = None

    results = data_quality_check_module.check_null_percentage(df, "clean_statistics", max_null_pct=5.0)
    round_tripped = json.loads(json.dumps(results))  # no default=str — must not raise

    for original, rt in zip(results, round_tripped):
        assert rt["passed"] is original["passed"]
        assert isinstance(rt["passed"], bool)


def test_check_schema_passes_with_all_critical_columns(data_quality_check_module, clean_df):
    result = data_quality_check_module.check_schema(clean_df, "clean_statistics")
    assert result["passed"] is True


def test_check_schema_fails_with_missing_column(data_quality_check_module, clean_df):
    df = clean_df.drop(columns=["views"])
    result = data_quality_check_module.check_schema(df, "clean_statistics")

    assert result["passed"] is False
    assert "views" in result["missing_columns"]


def test_check_value_ranges_passes_within_bounds(data_quality_check_module, clean_df):
    results = data_quality_check_module.check_value_ranges(clean_df, "clean_statistics", max_views=1000)
    assert results[0]["passed"] is True


def test_check_value_ranges_fails_on_extreme_value(data_quality_check_module, clean_df):
    df = clean_df.copy()
    df.loc[0, "views"] = 99_999_999_999

    results = data_quality_check_module.check_value_ranges(df, "clean_statistics", max_views=1000)

    assert results[0]["passed"] is False
    assert results[0]["extreme_count"] == 1


def test_check_value_ranges_result_is_json_safe(data_quality_check_module, clean_df):
    df = clean_df.copy()
    df.loc[0, "views"] = -5

    results = data_quality_check_module.check_value_ranges(df, "clean_statistics", max_views=1000)
    round_tripped = json.loads(json.dumps(results))  # no default=str — must not raise

    assert round_tripped[0]["passed"] is False
    assert isinstance(round_tripped[0]["passed"], bool)


def test_check_value_ranges_skips_non_statistics_tables(data_quality_check_module, clean_df):
    results = data_quality_check_module.check_value_ranges(clean_df, "clean_reference_data", max_views=1000)
    assert results == []
