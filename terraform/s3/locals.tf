#################################################
# Shared locals for the S3 module
#################################################

locals {
  name_prefix = "yt-data-pipeline"

  # Individual bucket names derived from the name_prefix + account_id pattern
  bronze_bucket        = "${local.name_prefix}-bronze-${data.aws_caller_identity.current.account_id}"
  silver_bucket        = "${local.name_prefix}-silver-${data.aws_caller_identity.current.account_id}"
  gold_bucket          = "${local.name_prefix}-gold-${data.aws_caller_identity.current.account_id}"
  query_results_bucket = "${local.name_prefix}-query-result-${data.aws_caller_identity.current.account_id}"
}
