resource "aws_glue_job" "bronze_to_silver_statistics_glue_job" {
  name = "bronze_to_silver_statistics"

  role_arn = data.terraform_remote_state.iam.outputs.glue_iam_role_arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  execution_class   = "STANDARD"

  timeout     = 60
  max_retries = 1

  command {
    name = "glueetl"

    script_location = "s3://yt-data-pipeline-bronze-prakhar/glue/scripts/bronze_to_silver_statistics.py"

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

    "--job-bookmark-option" = "job-bookmark-enable"

    "--TempDir" = "s3://yt-data-pipeline-bronze-prakhar/glue/temp/"

    #################################################
    # Environment
    #################################################

    "--ENV" = "dev"

    #################################################
    # Bronze Layer Parameters
    #################################################

    "--bronze_database" = "yt-pipeline-bronze-dev"

    "--bronze_table" = "raw_statistics"

    #################################################
    # Silver Layer Parameters
    #################################################

    "--silver_bucket" = "yt-data-pipeline-silver-prakhar"

    "--silver_database" = "yt-pipeline-silver-dev"

    "--silver_table" = "clean_statistics"

    "--silver_path" = "youtube/clean_statistics/"

    #################################################
    # Optional Additional Buckets
    #################################################

    "--S3_BUCKET_BRONZE" = "yt-data-pipeline-bronze-prakhar"

    "--S3_BUCKET_SILVER" = "yt-data-pipeline-silver-prakhar"

    "--S3_BUCKET_GOLD" = "yt-data-pipeline-gold-prakhar"
  }

  tags = {
    Name        = "bronze_to_silver_statistics"
    Environment = "dev"
  }

  depends_on = [
    aws_s3_object.bronze_to_silver_statistics_glue_script
  ]
}