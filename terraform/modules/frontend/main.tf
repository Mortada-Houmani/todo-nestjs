# ==============================================================================
# modules/frontend/main.tf
#
# S3 bucket that holds the built React app (vite build output).
# CloudFront (in the cloudfront module) serves the files from this bucket.
#
# The bucket is private — only CloudFront can access it via an OAC.
# ==============================================================================

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project}-frontend-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project}-frontend-${var.environment}"
    Environment = var.environment
  }
}


# Block all public access — CloudFront will serve the files, not S3 directly
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning so you can roll back a bad deployment
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}
