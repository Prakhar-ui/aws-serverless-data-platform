#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "json_to_parquet_function_zip" {

  type = "zip"

  source_dir = "${path.module}/scripts/json_to_parquet"

  output_path = "${path.module}/json_to_parquet_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "json_to_parquet_function" {

  function_name = "${local.name_prefix}-json-to-parquet-dev"

  #################################################
  # Lambda Package
  #################################################

  filename = data.archive_file.json_to_parquet_function_zip.output_path

  source_code_hash = data.archive_file.json_to_parquet_function_zip.output_base64sha256

  #################################################
  # IAM Role
  #################################################

  role = data.terraform_remote_state.iam.outputs.lambda_iam_role_arn

  #################################################
  # Runtime
  #################################################

  runtime = "python3.12"

  handler = "lambda_function.lambda_handler"

  architectures = ["x86_64"]

  #################################################
  # AWS SDK Pandas Layer (awswrangler)
  #################################################

  layers = [
    "arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python312:16"
  ]

  #################################################
  # Lambda Configuration
  #################################################

  timeout = 300

  memory_size = 512

  #################################################
  # Ephemeral Storage
  #################################################

  ephemeral_storage {
    size = 1024
  }

  #################################################
  # Environment Variables
  #################################################

  environment {

    variables = {

      S3_BUCKET_BRONZE = format("%s-bronze-%s", local.name_prefix, local.account_id)

      S3_BUCKET_SILVER = format("%s-silver-%s", local.name_prefix, local.account_id)

      GLUE_DB_SILVER = "yt_pipeline_silver_dev"

      GLUE_TABLE_REFERENCE = "clean_reference_data"

      SNS_ALERT_TOPIC_ARN = format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)

      ENV = "dev"
    }
  }

  #################################################
  # Tags
  #################################################

  tags = {

    Name = "${local.name_prefix}-json-to-parquet-dev"

    Environment = "dev"

    Project = local.name_prefix
  }
}
