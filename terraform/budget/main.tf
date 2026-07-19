locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "yt-data-pipeline"
}

#################################################
# Monthly Cost Budget with alerts
#################################################

resource "aws_budgets_budget" "monthly_budget" {
  name         = format("%s-monthly-budget-dev", local.name_prefix)
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"

  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["prakha8380@gmail.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["prakha8380@gmail.com"]
  }

  cost_filter {
    name = "TagKeyValue"
    values = [
      format("Project$%s", local.name_prefix)
    ]
  }

  tags = {
    Name        = format("%s-monthly-budget-dev", local.name_prefix)
    Environment = "dev"
    Project     = local.name_prefix
  }
}
