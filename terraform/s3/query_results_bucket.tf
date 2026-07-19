# Create Query Result S3 Bucket
resource "aws_s3_bucket" "query_result_bucket" {
  bucket = local.query_results_bucket

  tags = {
    Name        = local.query_results_bucket
    Environment = "dev"
    Project     = "yt-data-pipeline"
    DataLayer   = "athena-results"
  }
}

# Enable Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "query_result_encryption" {
  bucket = aws_s3_bucket.query_result_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "query_result_public_access" {
  bucket = aws_s3_bucket.query_result_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: Athena query results expire after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "query_result_lifecycle" {
  bucket = aws_s3_bucket.query_result_bucket.id

  rule {
    id     = "query-results-expiry"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }
  }
}
