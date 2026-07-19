resource "aws_glue_job" "silver_to_gold_analytics_glue_job" {
  name = "silver_to_gold_analytics"

  role_arn = data.terraform_remote_state.iam.outputs.glue_iam_role_arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  execution_class   = "STANDARD"

  timeout     = 60
  max_retries = 1

  command {
    name = "glueetl"

    script_location = format("s3://%s-bronze-%s/glue/scripts/silver_to_gold_analytics.py", local.name_prefix, local.account_id)

    python_version = "3"
  }

  default_arguments = {
    #################################################
    # Glue Configuration
    #################################################

    "--job-language" = "python"

    "--enable-continuous-cloudwatch-log" = "true"

    "--enable-metrics" = "true"

    "--enable-glue-datacatalog" = "true"

    # NOTE: job bookmarks are intentionally NOT enabled here. This job recomputes
    # cumulative aggregates (total views, rankings, etc.) over the entire Silver
    # table on every run. Bookmarking would make it see only newly-bookmarked
    # Silver rows, producing incomplete/incorrect aggregates. Bookmarking is only
    # safe on bronze_to_silver, which does row-level append processing.

    "--TempDir" = format("s3://%s-bronze-%s/glue/temp/", local.name_prefix, local.account_id)

    #################################################
    # PySpark Performance Configuration
    #################################################

    "--conf" = "spark.sql.shuffle.partitions=4 spark.sql.adaptive.enabled=true"

    #################################################
    # Environment
    #################################################

    "--ENV" = "dev"

    #################################################
    # Silver Layer Parameters
    #################################################

    "--silver_database" = "yt_pipeline_silver_dev"

    #################################################
    # Gold Layer Parameters
    #################################################

    "--gold_bucket" = format("%s-gold-%s", local.name_prefix, local.account_id)

    "--gold_database" = "yt_pipeline_gold_dev"

    #################################################
    # Reference Data (for category_name join)
    #################################################

    "--reference_table" = "clean_reference_data"

    #################################################
    # Optional Additional Buckets
    #################################################

    "--S3_BUCKET_BRONZE" = format("%s-bronze-%s", local.name_prefix, local.account_id)

    "--S3_BUCKET_SILVER" = format("%s-silver-%s", local.name_prefix, local.account_id)

    "--S3_BUCKET_GOLD" = format("%s-gold-%s", local.name_prefix, local.account_id)
  }

  tags = {
    Name        = "silver_to_gold_analytics"
    Environment = "dev"
    Project     = local.name_prefix
  }

  depends_on = [
    aws_s3_object.silver_to_gold_analytics_glue_script
  ]
}
