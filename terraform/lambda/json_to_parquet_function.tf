#################################################
# Fetch Existing IAM Remote State
#################################################

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = "yt-terraform-state-prakhar"
    key    = "iam/terraform.tfstate"
    region = "ap-south-1"
  }
}

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

resource "aws_lambda_function" "yt_lambda" {
  function_name = "yt-data-pipeline-json-to-parquet-dev"

  filename = data.archive_file.json_to_parquet_function_zip.output_path

  source_code_hash = data.archive_file.json_to_parquet_function_zip.output_base64sha256

  role = data.terraform_remote_state.iam.outputs.lambda_iam_role_arn

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      BRONZE_BUCKET = "yt-data-pipeline-bronze-prakhar"
      SILVER_BUCKET = "yt-data-pipeline-silver-prakhar"
      GOLD_BUCKET   = "yt-data-pipeline-gold-prakhar"
      ENV           = "dev"
    }
  }

  tags = {
    Name        = "yt-data-pipeline-lambda-dev"
    Environment = "dev"
  }
}