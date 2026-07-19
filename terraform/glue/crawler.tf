#################################################
# Glue Crawler - Bronze Layer
#################################################

resource "aws_glue_crawler" "bronze_crawler" {
  name          = "${local.name_prefix}-bronze-crawler-dev"
  role          = data.terraform_remote_state.iam.outputs.glue_iam_role_arn
  database_name = aws_glue_catalog_database.bronze_db.name

  description = "Glue crawler for YouTube raw statistics data"

  s3_target {
    path = format("s3://%s-bronze-%s/youtube/raw_statistics/", local.name_prefix, local.account_id)
  }

  s3_target {
    path = format("s3://%s-bronze-%s/youtube/raw_statistics_reference_data/", local.name_prefix, local.account_id)
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  tags = {
    Name        = "${local.name_prefix}-bronze-crawler-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}
