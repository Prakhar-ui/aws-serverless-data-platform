terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "step_functions/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
    encrypt        = true
  }
}