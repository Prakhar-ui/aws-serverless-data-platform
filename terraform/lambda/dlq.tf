#################################################
# Dead Letter Queue for Lambda failures
#################################################

resource "aws_sqs_queue" "lambda_dlq" {
  name = format("%s-lambda-dlq-dev", local.name_prefix)

  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = format("%s-lambda-dlq-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}

#################################################
# DLQ Queue Policy — allows Lambda to send messages
#################################################

resource "aws_sqs_queue_policy" "lambda_dlq_policy" {
  queue_url = aws_sqs_queue.lambda_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

#################################################
# Lambda Event Invoke Config — async invocation DLQ
#################################################

resource "aws_lambda_function_event_invoke_config" "youtube_ingestion_invoke_config" {
  function_name = aws_lambda_function.youtube_api_integration_function.function_name

  maximum_retry_attempts = 2

  destination_config {
    on_failure {
      destination = aws_sqs_queue.lambda_dlq.arn
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "dq_invoke_config" {
  function_name = aws_lambda_function.data_quality_check_function.function_name

  maximum_retry_attempts = 2

  destination_config {
    on_failure {
      destination = aws_sqs_queue.lambda_dlq.arn
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "json_to_parquet_invoke_config" {
  function_name = aws_lambda_function.json_to_parquet_function.function_name

  maximum_retry_attempts = 2

  destination_config {
    on_failure {
      destination = aws_sqs_queue.lambda_dlq.arn
    }
  }
}
