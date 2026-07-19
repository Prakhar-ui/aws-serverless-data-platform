terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "s3/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
    encrypt        = true
  }
}