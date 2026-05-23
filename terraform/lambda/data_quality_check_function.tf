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
  function_name = "yt-data-pipeline-data-quality-check"

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
      SNS_ALERT_TOPIC_ARN    = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"
      DQ_MIN_ROW_COUNT       = "10"
      DQ_MAX_NULL_PERCENT    = "5.0"
      ATHENA_OUTPUT_LOCATION = "s3://yt-data-pipeline-query-result-prakhar/"


      ENV = "dev"
    }
  }

  #################################################
  # Tags
  #################################################

  tags = {
    Name        = "data_quality_check"
    Environment = "dev"
  }
}