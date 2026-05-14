#################################################
# Create Lambda ZIP Package
#################################################

data "archive_file" "youtube_api_integstion_function_zip" {
  type = "zip"

  source_file = "${path.module}/scripts/youtube_api_integstion/lambda_function.py"

  output_path = "${path.module}/youtube_api_integstion_function.zip"
}

#################################################
# Lambda Function
#################################################

resource "aws_lambda_function" "youtube_api_integstion_function" {

  function_name = "yt-data-pipeline-youtube-ingestion-dev"

  filename = data.archive_file.youtube_api_integstion_function_zip.output_path

  source_code_hash = data.archive_file.youtube_api_integstion_function_zip.output_base64sha256

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
    Name        = "yt-data-pipeline-youtube-ingestion-dev"
    Environment = "dev"
  }
}