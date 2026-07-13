import json
import os
import logging
from datetime import datetime, timezone
from urllib.parse import unquote_plus

import pandas as pd
import boto3
import awswrangler as wr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ── Configuration ────────────────────────────────────────────────────────────

def get_config():
    """Loads environment variables dynamically so tests can override them."""
    return {
        "silver_bucket": os.environ.get("S3_BUCKET_SILVER", "mock-bucket"),
        "glue_db": os.environ.get("GLUE_DB_SILVER"),
        "glue_table": os.environ.get("GLUE_TABLE_REFERENCE"),
        "sns_topic": os.environ.get("SNS_ALERT_TOPIC_ARN")
    }

# ── Pure Business Logic (No AWS dependencies) ────────────────────────────────

def extract_s3_records(event: dict) -> list:
    """Parses the event to extract a list of (bucket, key) tuples."""
    records_data = event.get("Records", [])
    if not records_data and "s3" in event:
        # Direct invocation fallback
        records_data = [event]

    parsed = []
    for record in records_data:
        if "s3" in record:
            bucket = record["s3"]["bucket"]["name"]
            key = unquote_plus(record["s3"]["object"]["key"])
            parsed.append((bucket, key))
    return parsed


def extract_region(key: str) -> str:
    """Extracts the region from the S3 key (e.g., path/region=US/file.json)."""
    for part in key.split("/"):
        if part.startswith("region="):
            return part.split("=")[1]
    return "unknown"


def normalize_json_to_df(raw_data: dict) -> pd.DataFrame:
    """Converts raw YouTube/Kaggle JSON into a pandas DataFrame."""
    if "items" in raw_data and isinstance(raw_data["items"], list):
        return pd.json_normalize(raw_data["items"])
    return pd.json_normalize(raw_data)


def validate_category_data(df: pd.DataFrame) -> pd.DataFrame:
    """Validates and deduplicates the category reference data."""
    if df.empty:
        raise ValueError("Empty DataFrame — no category items found")

    required_cols = {"id", "snippet.title"}
    actual_cols = set(df.columns)
    missing = required_cols - actual_cols
    
    if missing:
        logger.warning(f"Missing expected columns: {missing}. Available: {actual_cols}")

    # Drop duplicate categories (same id)
    before = len(df)
    if "id" in df.columns:
        df = df.drop_duplicates(subset=["id"], keep="last")
    after = len(df)
    
    if before != after:
        logger.info(f"  Removed {before - after} duplicate categories")

    return df


def enrich_data(df: pd.DataFrame, key: str, region: str) -> pd.DataFrame:
    """Adds processing metadata to the DataFrame."""
    df["_ingestion_timestamp"] = datetime.now(timezone.utc).isoformat()
    df["_source_file"] = key
    df["region"] = region
    return df

# ── AWS I/O Adapters (Easily mockable) ───────────────────────────────────────

def read_json_from_s3(bucket: str, key: str) -> dict:
    """Reads raw JSON from S3 using boto3."""
    s3_client = boto3.client("s3")
    response = s3_client.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8")
    return json.loads(content)


def write_to_silver(df: pd.DataFrame, config: dict):
    """Writes the cleaned DataFrame to the Silver bucket via AWS Wrangler."""
    silver_path = f"s3://{config['silver_bucket']}/youtube/reference_data/"
    wr.s3.to_parquet(
        df=df,
        path=silver_path,
        dataset=True,
        database=config["glue_db"],
        table=config["glue_table"],
        partition_cols=["region"],
        mode="overwrite_partitions",
        schema_evolution=True,
    )
    return silver_path


def send_alert(sns_topic: str, subject: str, message: str):
    """Sends a failure alert to SNS."""
    if sns_topic:
        sns_client = boto3.client("sns")
        sns_client.publish(TopicArn=sns_topic, Subject=subject[:100], Message=message)

# ── Main Handler ─────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    """Process S3 event for new JSON reference files."""
    config = get_config()
    records = extract_s3_records(event)

    processed = []
    errors = []

    for bucket, key in records:
        try:
            logger.info(f"Processing: s3://{bucket}/{key}")

            # 1. Read (I/O)
            raw_data = read_json_from_s3(bucket, key)

            # 2. Transform (Pure Logic)
            df = normalize_json_to_df(raw_data)
            df = validate_category_data(df)
            region = extract_region(key)
            df = enrich_data(df, key, region)

            logger.info(f"  Clean shape: {df.shape}, region: {region}")

            # 3. Write (I/O)
            silver_path = write_to_silver(df, config)
            logger.info(f"  Written to Silver: {silver_path}")

            processed.append({"key": key, "region": region, "rows": len(df)})

        except Exception as e:
            logger.error(f"Error processing record {key}: {e}", exc_info=True)
            errors.append({"key": key, "error": str(e)})

    # 4. Alert on Failure
    if errors:
        send_alert(
            config["sns_topic"],
            subject="[YT Pipeline] Silver reference transform failed",
            message=json.dumps(errors, indent=2),
        )

    return {
        "statusCode": 200,
        "processed": processed,
        "errors": errors,
    }