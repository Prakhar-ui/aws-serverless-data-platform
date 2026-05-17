resource "aws_glue_job" "silver_to_gold_statistics_glue_job" {
  name = "silver_to_gold_statistics"

  role_arn = data.terraform_remote_state.iam.outputs.glue_iam_role_arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  execution_class   = "STANDARD"

  timeout     = 60
  max_retries = 1

  command {
    name = "glueetl"

    script_location = "s3://yt-data-pipeline-bronze-prakhar/glue/scripts/silver_to_gold_statistics.py"

    python_version = "3"
  }

  default_arguments = {
    "--job-language" = "python"

    "--enable-continuous-cloudwatch-log" = "true"

    "--enable-metrics" = "true"

    "--enable-glue-datacatalog" = "true"

    "--TempDir" = "s3://yt-data-pipeline-bronze-prakhar/glue/temp/"

    "--ENV" = "dev"

    "--S3_BUCKET_BRONZE" = "yt-data-pipeline-bronze-prakhar"

    "--S3_BUCKET_SILVER" = "yt-data-pipeline-silver-prakhar"

    "--S3_BUCKET_GOLD" = "yt-data-pipeline-gold-prakhar"
  }

  tags = {
    Name        = "silver_to_gold_statistics"
    Environment = "dev"
  }

  depends_on = [
    aws_s3_object.silver_to_gold_statistics_glue_job
  ]
}