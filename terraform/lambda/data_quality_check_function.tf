#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "data_quality_check_function_zip" {
  type = "zip"

  source_dir = "${path.module}/scripts/data_quality_check"

  output_path = "${path.module}/data_quality_check_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "data_quality_check_function" {
  function_name = "${local.name_prefix}-data-quality-check"

  filename = data.archive_file.data_quality_check_function_zip.output_path

  source_code_hash = data.archive_file.data_quality_check_function_zip.output_base64sha256

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
      SNS_ALERT_TOPIC_ARN    = format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)
      DQ_MIN_ROW_COUNT       = "10"
      DQ_MAX_NULL_PERCENT    = "5.0"
      ATHENA_OUTPUT_LOCATION = format("s3://%s-query-result-%s/athena-results/", local.name_prefix, local.account_id)
      ATHENA_WORKGROUP       = "primary"

      ENV = "dev"
    }
  }

  #################################################
  # Tags
  #################################################

  tags = {
    Name        = "${local.name_prefix}-data-quality-check"
    Environment = "dev"
    Project     = local.name_prefix
  }
}
