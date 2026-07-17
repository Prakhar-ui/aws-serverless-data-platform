#################################################
# Step Function IAM Role
#################################################

resource "aws_iam_role" "step_function_role" {
  name = "yt-data-pipeline-step_functions-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "states.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "yt-data-pipeline-step_functions-role-dev"
    Environment = "dev"
  }
}

#################################################
# Custom Inline Policy
#################################################

resource "aws_iam_role_policy" "step_function_inline_policy" {
  name = "yt-data-pipeline-step_functions-inline-policy-dev"

  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      #################################################
      # Lambda Invoke Permissions
      #################################################

      {
        Sid    = "LambdaInvokeAccess"
        Effect = "Allow"

        Action = [
          "lambda:InvokeFunction"
        ]

        Resource = [
          "arn:aws:lambda:ap-south-1:585008079281:function:yt-data-pipeline-data-quality-check",
          "arn:aws:lambda:ap-south-1:585008079281:function:yt-data-pipeline-json-to-parquet-dev",
          "arn:aws:lambda:ap-south-1:585008079281:function:yt-data-pipeline-youtube-ingestion-dev"
        ]

      },

      #################################################
      # Glue Job Permissions
      #################################################

      {
        Sid    = "GlueJobAccess"
        Effect = "Allow"

        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]

        Resource = "*"
      },

      #################################################
      # Glue Crawler Permissions
      #################################################

      {
        Sid    = "GlueCrawlerAccess"
        Effect = "Allow"

        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler"
        ]

        Resource = "*"
      },

      #################################################
      # SNS Publish Permissions
      #################################################

      {
        Sid    = "SNSPublishAccess"
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"

      }
    ]
  })
}