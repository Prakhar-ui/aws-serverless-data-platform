terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "monitoring/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
    encrypt        = true
  }
}
