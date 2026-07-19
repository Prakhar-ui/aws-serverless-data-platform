terraform {
  backend "s3" {
    bucket         = "yt-terraform-state-prakhar"
    key            = "monitoring/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
