#################################################
# EventBridge Schedule Rule
#
# Triggers the pipeline once a day. Adjust schedule_expression
# to taste (e.g. "rate(6 hours)" for more frequent trending
# snapshots). Cron is in UTC.
#################################################

resource "aws_cloudwatch_event_rule" "pipeline_schedule" {
  name        = "yt-data-pipeline-daily-trigger-dev"
  description = "Triggers the YouTube data pipeline Step Function on a daily schedule"

  schedule_expression = "cron(0 3 * * ? *)"

  state = "ENABLED"

  tags = {
    Name        = "yt-data-pipeline-daily-trigger-dev"
    Environment = "dev"
  }
}

#################################################
# EventBridge Target — the Step Functions state machine
#################################################

resource "aws_cloudwatch_event_target" "pipeline_target" {
  rule = aws_cloudwatch_event_rule.pipeline_schedule.name

  arn      = data.terraform_remote_state.step_functions.outputs.step_function_arn
  role_arn = data.terraform_remote_state.iam.outputs.eventbridge_role_arn

  input = jsonencode({
    triggered_by = "eventbridge_schedule"
  })
}
