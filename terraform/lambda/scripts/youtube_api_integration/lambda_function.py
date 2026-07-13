import json
import os
import logging
from datetime import datetime, timezone
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode

import boto3

# ── Logging ──────────────────────────────────────────────────────────────────
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ── Configuration ────────────────────────────────────────────────────────────
def get_config() -> dict:
    """Loads environment variables lazily so tests can import this module safely."""
    return {
        "api_key": os.environ.get("YOUTUBE_API_KEY", "MOCK_KEY"),
        "bucket": os.environ.get("S3_BUCKET_BRONZE", "mock-bucket"),
        "regions": os.environ.get("YOUTUBE_REGIONS", "US,GB,CA,DE,FR,IN,JP,KR,MX,RU").split(","),
        "sns_topic": os.environ.get("SNS_ALERT_TOPIC_ARN"),
        "api_base": "https://www.googleapis.com/youtube/v3",
        "max_results": 50,
    }


# ── Pure Business Logic (No I/O, highly testable) ────────────────────────────

def build_api_url(api_base: str, endpoint: str, params: dict) -> str:
    """Constructs the YouTube API URL with properly encoded parameters."""
    return f"{api_base}/{endpoint}?{urlencode(params)}"


def generate_s3_keys(region: str, now: datetime, ingestion_id: str) -> dict:
    """Generates the Hive-partitioned S3 keys for trending and category data."""
    date_partition = now.strftime("%Y-%m-%d")
    hour_partition = now.strftime("%H")
    
    return {
        "trending": (
            f"youtube/raw_statistics/"
            f"region={region}/"
            f"date={date_partition}/"
            f"hour={hour_partition}/"
            f"{ingestion_id}.json"
        ),
        "categories": (
            f"youtube/raw_statistics_reference_data/"
            f"region={region}/"
            f"date={date_partition}/"
            f"{region}_category_id.json"
        )
    }


def enrich_with_metadata(data: dict, ingestion_id: str, region: str, now: datetime) -> dict:
    """Injects pipeline tracing metadata directly into the JSON response."""
    data["_pipeline_metadata"] = {
        "ingestion_id": ingestion_id,
        "region": region,
        "ingestion_timestamp": now.isoformat(),
        "source": "youtube_data_api_v3",
    }
    if "items" in data:
        data["_pipeline_metadata"]["item_count"] = len(data["items"])
        
    return data


# ── Network & AWS I/O Adapters (Easily mockable in tests) ────────────────────

def fetch_json_from_api(url: str) -> dict:
    """Executes the HTTP GET request and parses the JSON response."""
    req = Request(url, headers={"Accept": "application/json"})
    with urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def write_to_s3(data: dict, bucket: str, key: str):
    """Writes the JSON data to S3."""
    s3_client = boto3.client("s3")
    body = json.dumps(data, ensure_ascii=False, indent=2)
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=body.encode("utf-8"),
        ContentType="application/json",
        Metadata={
            "ingestion_timestamp": datetime.now(timezone.utc).isoformat(),
            "source": "youtube_data_api_v3",
        },
    )


def send_alert(topic_arn: str, subject: str, message: str):
    """Sends a failure alert via SNS."""
    if topic_arn:
        sns_client = boto3.client("sns")
        sns_client.publish(TopicArn=topic_arn, Subject=subject[:100], Message=message)


# ── Main Handler ─────────────────────────────────────────────────────────────

def lambda_handler(event, context):
    """Main execution orchestrator."""
    config = get_config()
    
    now = datetime.now(timezone.utc)
    ingestion_id = now.strftime("%Y%m%d_%H%M%S")
    results = {"success": [], "failed": []}

    for region in config["regions"]:
        region = region.strip().lower()
        logger.info(f"Processing region: {region}")
        
        s3_keys = generate_s3_keys(region, now, ingestion_id)

        # 1. Fetch & Store Trending Videos
        try:
            trending_url = build_api_url(config["api_base"], "videos", {
                "part": "snippet,statistics,contentDetails",
                "chart": "mostPopular",
                "regionCode": region,
                "maxResults": config["max_results"],
                "key": config["api_key"],
            })
            
            trending_data = fetch_json_from_api(trending_url)
            trending_data = enrich_with_metadata(trending_data, ingestion_id, region, now)
            
            write_to_s3(trending_data, config["bucket"], s3_keys["trending"])
            logger.info(f"  Wrote videos → s3://{config['bucket']}/{s3_keys['trending']}")
            
        except Exception as e:
            logger.error(f"  Error for {region} trending: {e}")
            results["failed"].append({"region": region, "type": "trending", "error": str(e)})
            continue

        # 2. Fetch & Store Categories
        try:
            category_url = build_api_url(config["api_base"], "videoCategories", {
                "part": "snippet",
                "regionCode": region,
                "key": config["api_key"],
            })
            
            category_data = fetch_json_from_api(category_url)
            category_data = enrich_with_metadata(category_data, ingestion_id, region, now)
            
            write_to_s3(category_data, config["bucket"], s3_keys["categories"])
            logger.info(f"  Wrote categories → s3://{config['bucket']}/{s3_keys['categories']}")
            
        except Exception as e:
            logger.error(f"  Error for {region} categories: {e}")
            results["failed"].append({"region": region, "type": "categories", "error": str(e)})
            continue

        results["success"].append(region)

    # 3. Summary & Alerting
    logger.info(
        f"Ingestion {ingestion_id} complete. "
        f"Success: {len(results['success'])}/{len(config['regions'])} regions. "
        f"Failed: {len(results['failed'])}."
    )

    if results["failed"]:
        send_alert(
            config["sns_topic"],
            subject=f"[YT Pipeline] Ingestion partial failure — {ingestion_id}",
            message=json.dumps(results, indent=2),
        )

    return {
        "statusCode": 200,
        "ingestion_id": ingestion_id,
        "results": results,
    }