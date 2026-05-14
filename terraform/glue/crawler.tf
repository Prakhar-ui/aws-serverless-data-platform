#################################################
# Glue Crawler - Bronze Layer
#################################################

resource "aws_glue_crawler" "bronze_crawler" {
  name          = "yt-data-pipeline-bronze-crawler-dev"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.bronze_db.name

  description = "Glue crawler for YouTube raw statistics data"

  s3_target {
    path = ["s3://yt-data-pipeline-bronze-prakhar/youtube/raw_statistics/", 
            "s3://yt-data-pipeline-bronze-prakhar/youtube/raw_statistics_reference_data/"]
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  tags = {
    Name        = "yt-data-pipeline-bronze-crawler-dev"
    Environment = "dev"
  }
}