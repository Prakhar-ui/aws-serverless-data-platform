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

    script_location = "s3://yt-data-pipeline-bronze-prakhar/glue/scripts/silver_to_gold_analytics.py"

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

    "--TempDir" = "s3://yt-data-pipeline-bronze-prakhar/glue/temp/"

    #################################################
    # Environment
    #################################################

    "--ENV" = "dev"

    #################################################
    # Silver Layer Parameters
    #################################################

    "--silver_database" = "yt-pipeline-silver-dev"

    #################################################
    # Gold Layer Parameters
    #################################################

    "--gold_bucket" = "yt-data-pipeline-gold-prakhar"

    "--gold_database" = "yt-pipeline-gold-dev"

    #################################################
    # Reference Data (for category_name join)
    #################################################

    "--reference_table" = "clean_reference_data"

    #################################################
    # Optional Additional Buckets
    #################################################

    "--S3_BUCKET_BRONZE" = "yt-data-pipeline-bronze-prakhar"

    "--S3_BUCKET_SILVER" = "yt-data-pipeline-silver-prakhar"

    "--S3_BUCKET_GOLD" = "yt-data-pipeline-gold-prakhar"
  }

  tags = {
    Name        = "silver_to_gold_analytics"
    Environment = "dev"
  }

  depends_on = [
    aws_s3_object.silver_to_gold_analytics_glue_script
  ]
}