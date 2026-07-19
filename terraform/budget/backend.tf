terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "budget/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
