#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "json_to_parquet_function_zip" {
  type = "zip"

  source_file = "${path.module}/scripts/json_to_parquet/lambda_function.py"

  output_path = "${path.module}/json_to_parquet_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "json_to_parquet_function" {
  function_name = "yt-data-pipeline-json-to-parquet-dev"

  filename         = data.archive_file.json_to_parquet_function_zip.output_path
  source_code_hash = data.archive_file.json_to_parquet_function_zip.output_base64sha256

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
      S3_BRONZE_BUCKET     = "yt-data-pipeline-bronze-prakhar"
      S3_SILVER_BUCKET     = "yt-data-pipeline-silver-prakhar"
      GLUE_DB_SILVER       = "yt-pipeline-silver-dev"
      GLUE_TABLE_REFERENCE = "clean_reference_data"

      SNS_ALERT_TOPIC_ARN = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"

      ENV = "dev"
    }
  }

  #################################################
  # Tags
  #################################################

  tags = {
    Name        = "yt-data-pipeline-json-to-parquet-dev"
    Environment = "dev"
  }
}