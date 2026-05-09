terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Create S3 Bucket
resource "aws_s3_bucket" "bronze_bucket" {
  bucket = "yt-data-pipeline-bronze-prakhar"
}

# Enable Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bronze_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bronze_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output bucket name
output "bucket_name" {
  value = aws_s3_bucket.bronze_bucket.bucket
}