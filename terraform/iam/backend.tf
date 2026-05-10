terraform {
    backend "iam" {
        bucket         = "yt-terraform-state-prakhar"
        key            = "iam/terraform.tfstate"
        region         = "ap-south-1"
        dynamodb_table = "terraform-locks"
        encrypt        = true
    }
}