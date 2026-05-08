variable "project" { type = string }
variable "environment" { type = string }
variable "s3_bucket_id" { type = string }
variable "s3_bucket_domain" { type = string }
variable "acm_certificate_arn" {
  type    = string
  default = ""
}
variable "aliases" {
  type    = list(string)
  default = []
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the ALB to route API requests to"
}


output "domain_name" {
  description = "The CloudFront distribution domain name (e.g. abc123.cloudfront.net)."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidation in CI/CD."
  value       = aws_cloudfront_distribution.frontend.id
}
