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
resource "aws_s3_bucket_server_side_encryption_configuration" "bronze_encryption" {
  bucket = aws_s3_bucket.bronze_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "bronze_public_access" {
  bucket = aws_s3_bucket.bronze_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output bucket name
output "bronze_bucket_name" {
  value = aws_s3_bucket.bronze_bucket.bucket
}

# Create S3 Bucket
resource "aws_s3_bucket" "silver_bucket" {
  bucket = "yt-data-pipeline-silver-prakhar"
}

# Enable Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "silver_encryption" {
  bucket = aws_s3_bucket.silver_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "silver_public_access" {
  bucket = aws_s3_bucket.silver_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output bucket name
output "silver_bucket_name" {
  value = aws_s3_bucket.silver_bucket.bucket
}

# Create S3 Bucket
resource "aws_s3_bucket" "gold_bucket" {
  bucket = "yt-data-pipeline-gold-prakhar"
}

# Enable Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "gold_encryption" {
  bucket = aws_s3_bucket.gold_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "gold_public_access" {
  bucket = aws_s3_bucket.gold_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output bucket name
output "gold_bucket_name" {
  value = aws_s3_bucket.gold_bucket.bucket
}