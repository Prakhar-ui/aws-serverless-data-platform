locals {
  name_prefix = "yt-data-pipeline"
}

resource "aws_sns_topic" "alerts_topic" {
  name = "${local.name_prefix}-alerts-dev"

  tags = {
    Name        = "${local.name_prefix}-alerts-dev"
    Environment = "dev"
    Project     = local.name_prefix
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = "prakha8380@gmail.com"
}
