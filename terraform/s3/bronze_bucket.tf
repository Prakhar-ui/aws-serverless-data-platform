# Create Bronze S3 Bucket
resource "aws_s3_bucket" "bronze_bucket" {
  bucket = local.bronze_bucket

  tags = {
    Name        = local.bronze_bucket
    Environment = "dev"
    Project     = "yt-data-pipeline"
    DataLayer   = "bronze"
  }
}

# Enable Encryption
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

# Lifecycle: Transition raw data to Glacier after 30 days, expire after 90
resource "aws_s3_bucket_lifecycle_configuration" "bronze_lifecycle" {
  bucket = aws_s3_bucket.bronze_bucket.id

  rule {
    id     = "bronze-retention"
    status = "Enabled"

    filter {
      prefix = "youtube/raw_statistics/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "bronze-reference-retention"
    status = "Enabled"

    filter {
      prefix = "youtube/raw_statistics_reference_data/"
    }

    expiration {
      days = 30
    }
  }
}
