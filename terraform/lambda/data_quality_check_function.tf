#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "data_quality_check_function_zip" {
  type = "zip"

  source_file = "${path.module}/scripts/data_quality_check/lambda_function.py"

  output_path = "${path.module}/data_quality_check_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "data_quality_check_function" {
  function_name = "yt-data-pipeline-data-quality-check"

  filename         = data.archive_file.data_quality_check_function_zip.output_path
  source_code_hash = data.archive_file.data_quality_check_function_zip.output_base64sha256

  role = data.terraform_remote_state.iam.outputs.lambda_iam_role_arn

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  #################################################
  # Lambda Configuration
  #################################################

  timeout     = 300
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
      SNS_ALERT_TOPIC_ARN = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"
      DQ_MIN_ROW_COUNT    = "10"
      DQ_MAX_NULL_PERCENT = "5.0"

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