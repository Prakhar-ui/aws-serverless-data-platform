resource "aws_iam_role" "lambda_role" {

  name = "${local.name_prefix}-lambda-role-dev"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-lambda-role-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}

#################################################
# AWS Managed Lambda Basic Execution Policy
#################################################

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {

  role = aws_iam_role.lambda_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#################################################
# Custom Policy — Scoped to least privilege
#################################################

resource "aws_iam_role_policy" "lambda_policy" {

  name = "${local.name_prefix}-lambda-policy-dev"

  role = aws_iam_role.lambda_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      #################################################
      # S3 Bucket Access (Read-only for Bronze, Write for Silver/Gold)
      # Lambda does NOT need s3:DeleteObject
      #################################################

      {
        Sid    = "S3ListBucketAccess"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          format("arn:aws:s3:::%s-bronze-%s", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-silver-%s", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-gold-%s", local.name_prefix, local.account_id)
        ]
      },

      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          format("arn:aws:s3:::%s-bronze-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-silver-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-gold-%s/*", local.name_prefix, local.account_id)
        ]
      },

      {
        Sid    = "S3WriteAccess"
        Effect = "Allow"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          format("arn:aws:s3:::%s-bronze-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-silver-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-gold-%s/*", local.name_prefix, local.account_id)
        ]
      },

      #################################################
      # AWS Glue Catalog Access
      #################################################

      {
        Sid    = "GlueCatalogAccess"
        Effect = "Allow"

        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
          "glue:BatchCreatePartition",
          "glue:UpdatePartition"
        ]

        Resource = [
          format("arn:aws:glue:%s:%s:catalog", local.region, local.account_id),
          format("arn:aws:glue:%s:%s:database/yt_pipeline_*", local.region, local.account_id),
          format("arn:aws:glue:%s:%s:table/yt_pipeline_*/*", local.region, local.account_id)
        ]
      },

      #################################################
      # SQS Access — Send messages to DLQ on failure
      #################################################

      {
        Sid    = "SQSSendMessageToDLQ"
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = format("arn:aws:sqs:%s:%s:%s-lambda-dlq-dev", local.region, local.account_id, local.name_prefix)
      },

      #################################################
      # SNS Access
      #################################################

      {
        Sid    = "SNSAccess"
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)
      },

      #################################################
      # Athena Access
      #################################################

      {
        Sid = "AthenaQueryAccess"

        Effect = "Allow"

        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "athena:GetWorkGroup"
        ]

        Resource = format("arn:aws:athena:%s:%s:workgroup/primary", local.region, local.account_id)
      },

      {
        Sid = "AthenaQueryResultsBucket"

        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]

        Resource = [
          format("arn:aws:s3:::%s-query-result-%s", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-query-result-%s/*", local.name_prefix, local.account_id)
        ]
      }

    ]
  })
}
