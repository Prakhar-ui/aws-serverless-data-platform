resource "aws_iam_role" "lambda_role" {

  name = "yt-data-pipeline-lambda-role-dev"

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
    Name        = "yt-data-pipeline-lambda-role-dev"
    Environment = "dev"
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
# Custom Policy
#################################################

resource "aws_iam_role_policy" "lambda_policy" {

  name = "yt-data-pipeline-lambda-policy-dev"

  role = aws_iam_role.lambda_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      #################################################
      # S3 Bucket Access
      #################################################

      {
        Sid    = "S3ListBucketAccess"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar",
          "arn:aws:s3:::yt-data-pipeline-silver-prakhar",
          "arn:aws:s3:::yt-data-pipeline-gold-prakhar"
        ]
      },

      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar/*",
          "arn:aws:s3:::yt-data-pipeline-silver-prakhar/*",
          "arn:aws:s3:::yt-data-pipeline-gold-prakhar/*"
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
          "arn:aws:glue:ap-south-1:585008079281:catalog",
          "arn:aws:glue:ap-south-1:585008079281:database/yt_pipeline_*",
          "arn:aws:glue:ap-south-1:585008079281:table/yt_pipeline_*/*"
        ]
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

        Resource = "arn:aws:sns:ap-south-1:585008079281:yt-data-pipeline-alerts-dev"
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

        Resource = "arn:aws:athena:ap-south-1:585008079281:workgroup/primary"
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
          "arn:aws:s3:::yt-data-pipeline-query-result-prakhar",
          "arn:aws:s3:::yt-data-pipeline-query-result-prakhar/*"
        ]
      }

    ]
  })
}