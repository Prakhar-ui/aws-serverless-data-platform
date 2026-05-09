terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}