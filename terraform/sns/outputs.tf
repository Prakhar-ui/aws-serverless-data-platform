output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.alerts_topic.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.alerts_topic.name
}

output "sns_subscription_arn" {
  description = "ARN of the email subscription"
  value       = aws_sns_topic_subscription.email_subscription.arn
}