#################################################
# Glue IAM Role
#################################################

resource "aws_iam_role" "glue_role" {

  name = "${local.name_prefix}-glue-role-dev"

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
    Name        = "${local.name_prefix}-glue-role-dev"
    Environment = "dev"
    Project     = local.name_prefix
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
# Custom Inline Policy — Scoped to least privilege per job
#################################################

resource "aws_iam_role_policy" "glue_inline_policy" {

  name = "${local.name_prefix}-glue-inline-policy-dev"

  role = aws_iam_role.glue_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      #################################################
      # S3 Access: Bronze → Silver only needs read Bronze + write Silver
      # Silver → Gold needs read Silver + write Gold
      # Neither needs DeleteObject
      #################################################

      # List access to all three buckets for job configuration
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

      # Read access: Bronze (raw) and Silver (cleaned) data
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          format("arn:aws:s3:::%s-bronze-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-silver-%s/*", local.name_prefix, local.account_id)
        ]
      },

      # Write access: Silver (cleaned) and Gold (aggregated) data
      {
        Sid    = "S3WriteAccess"
        Effect = "Allow"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          format("arn:aws:s3:::%s-silver-%s/*", local.name_prefix, local.account_id),
          format("arn:aws:s3:::%s-gold-%s/*", local.name_prefix, local.account_id)
        ]
      }
    ]
  })
}

#################################################
# Glue Scripts Bucket Access (Glue jobs read scripts from Bronze)
#################################################

resource "aws_iam_role_policy" "glue_scripts_policy" {

  name = "${local.name_prefix}-glue-scripts-policy-dev"

  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3ScriptsAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          format("arn:aws:s3:::%s-bronze-%s/glue/scripts/*", local.name_prefix, local.account_id)
        ]
      }
    ]
  })
}
