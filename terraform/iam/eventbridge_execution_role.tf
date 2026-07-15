#################################################
# EventBridge IAM Role
#################################################

resource "aws_iam_role" "eventbridge_role" {

  name = "yt-data-pipeline-eventbridge-role-dev"

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
    Name        = "yt-data-pipeline-eventbridge-role-dev"
    Environment = "dev"
  }
}

#################################################
# Custom Inline Policy — Start the Step Function only
#################################################

resource "aws_iam_role_policy" "eventbridge_inline_policy" {

  name = "yt-data-pipeline-eventbridge-inline-policy-dev"

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
          "arn:aws:states:ap-south-1:585008079281:stateMachine:yt-data-pipeline-orchestration-dev"
        ]
      }
    ]
  })
}
