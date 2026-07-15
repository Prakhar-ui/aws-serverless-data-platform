#################################################
# Fetch IAM Remote State
#################################################

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = "yt-terraform-state-prakhar"
    key    = "iam/terraform.tfstate"
    region = "ap-south-1"
  }
}

#################################################
# Fetch Step Functions Remote State
#################################################

data "terraform_remote_state" "step_functions" {
  backend = "s3"

  config = {
    bucket = "yt-terraform-state-prakhar"
    key    = "step_functions/terraform.tfstate"
    region = "ap-south-1"
  }
}
