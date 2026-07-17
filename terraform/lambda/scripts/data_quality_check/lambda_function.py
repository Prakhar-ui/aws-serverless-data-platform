import os
import json
import logging
from datetime import datetime, timezone, timedelta

import boto3
import awswrangler as wr
import pandas as pd

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ── Configuration (Loaded dynamically for testability) ───────────────────────
def get_config():
    """Loads environment variables dynamically so tests can override them."""
    return {
        "sns_topic": os.environ.get("SNS_ALERT_TOPIC_ARN", ""),
        "athena_output": os.environ.get("ATHENA_OUTPUT_LOCATION"),
        "athena_workgroup": os.environ.get("ATHENA_WORKGROUP"),
        "min_row_count": int(os.environ.get("DQ_MIN_ROW_COUNT", "10")),
        "max_null_pct": float(os.environ.get("DQ_MAX_NULL_PERCENT", "5.0")),
        "max_views": 50_000_000_000,
        "freshness_hours": 48
    }

CRITICAL_COLUMNS = {
    "clean_statistics": [
        "video_id",
        "title",
        "channel_title",
        "views",
        "region"
    ]
}

# ── Core Business Logic (Pure functions, no AWS dependencies) ────────────────

def check_row_count(df: pd.DataFrame, table_name: str, min_count: int) -> dict:
    count = len(df)
    passed = count >= min_count
    return {
        "check": "row_count",
        "table": table_name,
        "value": count,
        "threshold": min_count,
        "passed": passed,
        "message": f"Row count: {count} (min: {min_count})",
    }


def check_null_percentage(df: pd.DataFrame, table_name: str, max_null_pct: float) -> list:
    results = []
    cols = CRITICAL_COLUMNS.get(table_name, [])

    for col in cols:
        if col not in df.columns:
            results.append({
                "check": "null_pct",
                "table": table_name,
                "column": col,
                "passed": False,
                "message": f"Column '{col}' missing from table",
            })
            continue

        null_pct = (df[col].isna().sum() / len(df)) * 100 if len(df) > 0 else 0
        passed = bool(null_pct <= max_null_pct)
        results.append({
            "check": "null_pct",
            "table": table_name,
            "column": col,
            "value": round(null_pct, 2),
            "threshold": max_null_pct,
            "passed": passed,
            "message": f"{col} null%: {null_pct:.2f}% (max: {max_null_pct}%)",
        })

    return results


def check_schema(df: pd.DataFrame, table_name: str) -> dict:
    expected = set(CRITICAL_COLUMNS.get(table_name, []))
    actual = set(df.columns)
    missing = expected - actual
    passed = len(missing) == 0
    return {
        "check": "schema",
        "table": table_name,
        "missing_columns": list(missing),
        "passed": passed,
        "message": f"Missing columns: {missing}" if missing else "All expected columns present",
    }


def check_value_ranges(df: pd.DataFrame, table_name: str, max_views: int) -> list:
    results = []
    if table_name != "clean_statistics" or "views" not in df.columns:
        return results

    negative = int((df["views"] < 0).sum())
    extreme = int((df["views"] > max_views).sum())
    passed = bool(negative == 0 and extreme == 0)
    
    results.append({
        "check": "value_range",
        "table": table_name,
        "column": "views",
        "negative_count": negative,
        "extreme_count": extreme,
        "passed": passed,
        "message": f"Views: {negative} negative, {extreme} extreme (>{max_views})",
    })

    return results


def check_freshness(df: pd.DataFrame, table_name: str, freshness_hours: int) -> dict:
    if "_processed_at" not in df.columns and "_ingestion_timestamp" not in df.columns:
        return {
            "check": "freshness",
            "table": table_name,
            "passed": True,
            "message": "No timestamp column found — skipping freshness check (backfill data)",
        }

    ts_col = "_processed_at" if "_processed_at" in df.columns else "_ingestion_timestamp"
    try:
        latest = pd.to_datetime(df[ts_col]).max()
        cutoff = datetime.now(timezone.utc) - timedelta(hours=freshness_hours)
        
        if latest.tzinfo is None:
            latest = latest.replace(tzinfo=timezone.utc)
            
        passed = latest >= cutoff
        return {
            "check": "freshness",
            "table": table_name,
            "latest_record": str(latest),
            "cutoff": str(cutoff),
            "passed": passed,
            "message": f"Latest: {latest}, Cutoff: {cutoff}",
        }
    except Exception as e:
        return {
            "check": "freshness",
            "table": table_name,
            "passed": True, # Fail open if unparseable
            "message": f"Could not parse timestamps: {e} — skipping",
        }


# ── AWS I/O Adapters (Easily mockable in tests) ──────────────────────────────

def fetch_table_data(database: str, table_name: str, athena_output: str, workgroup: str) -> pd.DataFrame:
    """Wrapper for AWS Wrangler to fetch Athena data."""
    query = f'SELECT * FROM "{table_name}" LIMIT 10000'
    return wr.athena.read_sql_query(
        sql=query,
        database=database,
        s3_output=athena_output,
        workgroup=workgroup,
    )

def send_failure_alert(sns_topic: str, failed_checks: list):
    """Wrapper for boto3 to send SNS alerts."""
    sns_client = boto3.client("sns", region_name="ap-south-1")
    sns_client.publish(
        TopicArn=sns_topic,
        Subject="[YT Pipeline] Data quality checks FAILED",
        Message=json.dumps(failed_checks, indent=2, default=str),
    )


# ── Main Handler ─────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    config = get_config()
    database = event.get("database", "yt_pipeline_silver_dev")
    tables = event.get("tables", ["clean_statistics"])

    all_results = []
    overall_passed = True

    for table_name in tables:
        logger.info(f"Running DQ checks on {database}.{table_name}...")

        try:
            df = fetch_table_data(
                database, 
                table_name, 
                config["athena_output"], 
                config["athena_workgroup"]
            )
        except Exception as e:
            logger.error(f"Could not read {table_name}: {e}")
            all_results.append({
                "check": "read_table",
                "table": table_name,
                "passed": False,
                "message": str(e),
            })
            overall_passed = False
            continue

        # Run checks and inject config parameters
        checks = []
        checks.append(check_row_count(df, table_name, config["min_row_count"]))
        checks.extend(check_null_percentage(df, table_name, config["max_null_pct"]))
        checks.append(check_schema(df, table_name))
        checks.extend(check_value_ranges(df, table_name, config["max_views"]))
        checks.append(check_freshness(df, table_name, config["freshness_hours"]))

        for check in checks:
            logger.info(f"  {check['check']}: {'PASS' if check['passed'] else 'FAIL'} — {check['message']}")
            if not check["passed"]:
                overall_passed = False

        all_results.extend(checks)

    # Summary and Alerting
    passed_count = sum(1 for r in all_results if r["passed"])
    total_count = len(all_results)
    
    logger.info(f"DQ Summary: {passed_count}/{total_count} passed. Overall: {'PASS' if overall_passed else 'FAIL'}")

    if not overall_passed and config["sns_topic"]:
        failed = [r for r in all_results if not r["passed"]]
        try:
            send_failure_alert(config["sns_topic"], failed)
        except Exception as e:
            logger.error(f"Failed to send SNS alert: {e}")

    return {
        "quality_passed": bool(overall_passed),
        "checks_passed": int(passed_count),
        "checks_total": int(total_count),
        "details": json.loads(json.dumps(all_results, default=str)),
    }