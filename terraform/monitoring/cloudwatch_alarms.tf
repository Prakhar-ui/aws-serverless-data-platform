#################################################
# CloudWatch Dashboard for Pipeline Monitoring
#################################################

resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = format("%s-dashboard-dev", local.name_prefix)

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", format("%s-youtube-ingestion-dev", local.name_prefix)],
            ["AWS/Lambda", "Errors", "FunctionName", format("%s-json-to-parquet-dev", local.name_prefix)],
            ["AWS/Lambda", "Errors", "FunctionName", format("%s-data-quality-check", local.name_prefix)]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Lambda Errors"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Glue", "glue.driver.aggregate.numCompletedSteps", "JobName", "bronze_to_silver_statistics", "JobRunId", "*"],
            ["AWS/Glue", "glue.driver.aggregate.numCompletedSteps", "JobName", "silver_to_gold_analytics", "JobRunId", "*"]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Glue Job Steps Completed"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsFailed", "StateMachineArn", format("arn:aws:states:%s:%s:stateMachine:%s-orchestration-dev", local.region, local.account_id, local.name_prefix)]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Step Function Failures"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", format("%s-youtube-ingestion-dev", local.name_prefix)],
            ["AWS/Lambda", "Duration", "FunctionName", format("%s-json-to-parquet-dev", local.name_prefix)],
            ["AWS/Lambda", "Duration", "FunctionName", format("%s-data-quality-check", local.name_prefix)]
          ]
          period = 300
          stat   = "Average"
          region = local.region
          title  = "Lambda Duration (ms)"
        }
      }
    ]
  })
}

#################################################
# Metric Alarms
#################################################

resource "aws_cloudwatch_metric_alarm" "ingestion_lambda_error_alarm" {
  alarm_name          = format("%s-ingestion-lambda-errors-dev", local.name_prefix)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert on YouTube ingestion Lambda errors"
  alarm_actions       = [format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)]

  dimensions = {
    FunctionName = format("%s-youtube-ingestion-dev", local.name_prefix)
  }

  tags = {
    Name        = format("%s-ingestion-lambda-errors-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}

resource "aws_cloudwatch_metric_alarm" "json_to_parquet_lambda_error_alarm" {
  alarm_name          = format("%s-json-to-parquet-lambda-errors-dev", local.name_prefix)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert on json_to_parquet Lambda errors"
  alarm_actions       = [format("arn:aws:sns:%s:%s:%s-alerts-dev", local.region, local.account_id, local.name_prefix)]

  dimensions = {
    FunctionName = format("%s-json-to-parquet-dev", local.name_prefix)
  }

  tags = {
    Name        = format("%s-json-to-parquet-lambda-errors-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}

resource "aws_cloudwatch_metric_alarm" "glue_job_failure_alarm" {
  alarm_name          = format("%s-glue-job-errors-dev", local.name_prefix)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "glue.driver.aggregate.numCompletedSteps"
  namespace           = "AWS/Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert on Glue job failures"
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = format("%s-glue-job-errors-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}

resource "aws_cloudwatch_metric_alarm" "step_function_failure_alarm" {
  alarm_name          = format("%s-step-function-failures-dev", local.name_prefix)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert on Step Function execution failures"
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = format("arn:aws:states:%s:%s:stateMachine:%s-orchestration-dev", local.region, local.account_id, local.name_prefix)
  }

  tags = {
    Name        = format("%s-step-function-failures-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}
