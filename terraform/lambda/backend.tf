terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "lambda/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}