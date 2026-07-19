#################################################
# Shared locals for the Monitoring module
#################################################

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "yt-data-pipeline"
}
