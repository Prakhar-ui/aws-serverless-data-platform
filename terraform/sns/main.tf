resource "aws_sns_topic" "alerts_topic" {
    name = "yt-data-pipeline-alerts-dev"

    tags = {
        Name = "yt-data-pipeline-alerts-dev"
        Environment = "dev"
    }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol = "email"
  endpoint = "prakha8380@gmail.com"
}