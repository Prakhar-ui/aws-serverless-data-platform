# Create Silver S3 Bucket
resource "aws_s3_bucket" "silver_bucket" {
  bucket = local.silver_bucket

  tags = {
    Name        = local.silver_bucket
    Environment = "dev"
    Project     = "yt-data-pipeline"
    DataLayer   = "silver"
  }
}

# Enable Encryption
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

# Lifecycle: Transition Silver data to Glacier after 60 days, expire after 180
resource "aws_s3_bucket_lifecycle_configuration" "silver_lifecycle" {
  bucket = aws_s3_bucket.silver_bucket.id

  rule {
    id     = "silver-retention"
    status = "Enabled"

    filter {
      prefix = "youtube/"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }
  }
}
