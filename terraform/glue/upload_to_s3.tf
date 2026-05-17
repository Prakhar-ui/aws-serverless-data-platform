resource "aws_s3_object" "bronze_to_silver_statistics_glue_script" {
  bucket = "yt-data-pipeline-bronze-prakhar"

  key = "glue/scripts/bronze_to_silver_statistics.py"

  source = "${path.module}/scripts/bronze_to_silver_statistics.py"

  etag = filemd5("${path.module}/scripts/bronze_to_silver_statistics.py")
}

resource "aws_s3_object" "silver_to_gold_analytics_glue_script" {
  bucket = "yt-data-pipeline-bronze-prakhar"

  key = "glue/scripts/silver_to_gold_analytics.py"

  source = "${path.module}/scripts/silver_to_gold_analytics.py"

  etag = filemd5("${path.module}/scripts/silver_to_gold_analytics.py")
}