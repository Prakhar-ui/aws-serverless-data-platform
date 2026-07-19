#################################################
# Step Function IAM Role
#################################################

resource "aws_iam_role" "step_function_role" {
  name = "${local.name_prefix}-step_functions-role-dev"

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
    Name        = "${local.name_prefix}-step_functions-role-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}

#################################################
# Custom Inline Policy — Scoped to least privilege
#################################################

resource "aws_iam_role_policy" "step_function_inline_policy" {
  name = "${local.name_prefix}-step_functions-inline-policy-dev"

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
          format("arn:aws:lambda:%s:%s:function:%s-data-quality-check", local.region, local.account_id, local.name_prefix),
          format("arn:aws:lambda:%s:%s:function:%s-json-to-parquet-dev", local.region, local.account_id, local.name_prefix),
          format("arn:aws:lambda:%s:%s:function:%s-youtube-ingestion-dev", local.region, local.account_id, local.name_prefix)
        ]
      },

      #################################################
      # Glue Job Permissions — scoped to specific job names
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

        Resource = [
          format("arn:aws:glue:%s:%s:job/bronze_to_silver_statistics", local.region, local.account_id),
          format("arn:aws:glue:%s:%s:job/silver_to_gold_analytics", local.region, local.account_id)
        ]
      },

      #################################################
      # Glue Crawler Permissions — scoped to bronze crawler
      #################################################

      {
        Sid    = "GlueCrawlerAccess"
        Effect = "Allow"

        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler"
        ]

        Resource = [
          format("arn:aws:glue:%s:%s:crawler/%s-bronze-crawler-dev", local.region, local.account_id, local.name_prefix)
        ]
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

        Resource = format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)

      }
    ]
  })
}
