#################################################
# EventBridge IAM Role
#################################################

resource "aws_iam_role" "eventbridge_role" {

  name = "${local.name_prefix}-eventbridge-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-eventbridge-role-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}

#################################################
# Custom Inline Policy — Start the Step Function only
#################################################

resource "aws_iam_role_policy" "eventbridge_inline_policy" {

  name = "${local.name_prefix}-eventbridge-inline-policy-dev"

  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "StartPipelineExecution"
        Effect = "Allow"

        Action = [
          "states:StartExecution"
        ]

        Resource = [
          format("arn:aws:states:%s:%s:stateMachine:%s-orchestration-dev", local.region, local.account_id, local.name_prefix)
        ]
      }
    ]
  })
}
