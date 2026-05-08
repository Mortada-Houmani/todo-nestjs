# ==============================================================================
# modules/cloudfront/main.tf
#
# CloudFront distribution — CDN that serves the React app from S3 globally.
#
# Key features:
#   • Origin Access Control (OAC) — only CloudFront can read the S3 bucket
#   • HTTPS-only with a modern TLS policy
#   • SPA support — 403/404 from S3 are rewritten to /index.html so React
#     Router can handle client-side routes
#   • Cache policy — static assets cached at edge for 1 day
# ==============================================================================

# ------------------------------------------------------------------------------
# Origin Access Control
# Replaces the older Origin Access Identity (OAI).
# Allows CloudFront to sign requests to S3 so the bucket can stay private.
# ------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project}-${var.environment}-oac"
  description                       = "OAC for ${var.project} frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ------------------------------------------------------------------------------
# S3 Bucket Policy
# Grants CloudFront (via OAC) read-only access to the bucket objects.
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipal"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "arn:aws:s3:::${var.s3_bucket_id}/*"
      Condition = {
        StringEquals = {
          # Only allow the specific CloudFront distribution
          "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
        }
      }
    }]
  })
}

# ------------------------------------------------------------------------------
# CloudFront Distribution
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"   # serve index.html when "/" is requested
  aliases             = var.aliases    # custom domain names (empty = use CF domain)
  price_class         = "PriceClass_100"  # US + Europe edge locations only (cheapest)
  comment             = "${var.project} ${var.environment} frontend"

  # --------------------------------------------------------------------------
  # S3 Origin — where CloudFront fetches the files from
  # --------------------------------------------------------------------------
  origin {
    domain_name              = var.s3_bucket_domain
    origin_id                = "s3-${var.s3_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # --------------------------------------------------------------------------
  # ALB Origin — where CloudFront sends API requests
  # --------------------------------------------------------------------------
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"  # Use HTTP to connect to the ALB since we skipped HTTPS on ALB
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --------------------------------------------------------------------------
  # API Cache Behaviour — applies to /api/* requests
  # --------------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Managed CachingDisabled policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # Managed AllViewerExceptHostHeader origin request policy
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    
    compress = true
  }

  # --------------------------------------------------------------------------
  # Default Cache Behaviour — applies to every request (S3)
  # --------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = "s3-${var.s3_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"   # HTTP → HTTPS redirect at edge

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Use the AWS managed CachingOptimized policy (caches based on query string)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    compress = true   # gzip/brotli compression at the edge
  }

  # --------------------------------------------------------------------------
  # SPA Error Pages
  # S3 returns 403 for missing objects (because the bucket is private).
  # We rewrite those responses to /index.html so React Router handles routing.
  # --------------------------------------------------------------------------
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # --------------------------------------------------------------------------
  # HTTPS / TLS
  # --------------------------------------------------------------------------
  viewer_certificate {
    # If a custom ACM cert ARN is provided, use it; otherwise fall back to the
    # default CloudFront *.cloudfront.net certificate.
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    acm_certificate_arn            = var.acm_certificate_arn == "" ? null : var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn == "" ? null : "sni-only"
    minimum_protocol_version       = var.acm_certificate_arn == "" ? "TLSv1" : "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"   # no geographic blocking
    }
  }

  tags = { Environment = var.environment }
}
