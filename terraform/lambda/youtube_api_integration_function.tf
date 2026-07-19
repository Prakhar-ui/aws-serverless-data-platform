#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "youtube_api_integration_function_zip" {
  type = "zip"

  source_file = "${path.module}/scripts/youtube_api_integration/lambda_function.py"

  output_path = "${path.module}/youtube_api_integration_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "youtube_api_integration_function" {
  function_name = "${local.name_prefix}-youtube-ingestion-dev"

  filename         = data.archive_file.youtube_api_integration_function_zip.output_path
  source_code_hash = data.archive_file.youtube_api_integration_function_zip.output_base64sha256

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
      YOUTUBE_API_KEY = var.youtube_api_key

      S3_BUCKET_BRONZE = format("%s-bronze-%s", local.name_prefix, local.account_id)

      SNS_ALERT_TOPIC_ARN = format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)

      YOUTUBE_REGIONS = "us,gb,in,ca,au,de,fr,jp,kr,ru"

      ENV = "dev"
    }
  }

  #################################################
  # Tags
  #################################################

  tags = {
    Name        = "${local.name_prefix}-youtube-ingestion-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}
