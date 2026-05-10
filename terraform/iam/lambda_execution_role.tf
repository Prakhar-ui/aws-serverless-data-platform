# Inline Policy for Bronze S3 Bucket Access
resource "aws_iam_role_policy" "lambda_bronze_s3_policy" {
  name = "lambda-bronze-s3-access-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = [
          "arn:aws:s3:::yt-data-pipeline-bronze-prakhar/*"
        ]
      }
    ]
  })
}