#################################################
# Shared locals for the Lambda module
#
# These are defined once and referenced by all .tf files in this directory.
# Terraform scopes all locals blocks to the module, so multiple definitions
# of the same local name would cause a DuplicateLocalValueDefn error.
#################################################

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "yt-data-pipeline"
}
