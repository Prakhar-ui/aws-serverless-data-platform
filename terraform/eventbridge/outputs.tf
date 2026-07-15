output "schedule_rule_name" {
  value = aws_cloudwatch_event_rule.pipeline_schedule.name
}

output "schedule_rule_arn" {
  value = aws_cloudwatch_event_rule.pipeline_schedule.arn
}

output "schedule_expression" {
  value = aws_cloudwatch_event_rule.pipeline_schedule.schedule_expression
}
