#################################################
# Glue IAM Role
#################################################

resource "aws_iam_role" "glue_role" {

  name = "yt-data-pipeline-glue-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "glue.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "yt-data-pipeline-glue-role-dev"
    Environment = "dev"
  }
}

#################################################
# AWS Managed Glue Service Role Policy
#################################################

resource "aws_iam_role_policy_attachment" "glue_service_role" {

  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#################################################
# Custom Inline Policy
#################################################

resource "aws_iam_role_policy" "glue_inline_policy" {

  name = "yt-data-pipeline-glue-inline-policy-dev"

  role = aws_iam_role.glue_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      #################################################
      # S3 Full Access for Required Buckets
      #################################################

      {
        Sid    = "S3FullAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]

        Resource = [

          # Bronze Bucket
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar",
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar/*",

          # Silver Bucket
          "arn:aws:s3:::yt-data-pipeline-silver-prakhar",
          "arn:aws:s3:::yt-data-pipeline-silver-prakhar/*",

          # Gold Bucket
          "arn:aws:s3:::yt-data-pipeline-gold-prakhar",
          "arn:aws:s3:::yt-data-pipeline-gold-prakhar/*"
        ]
      }
    ]
  })
}