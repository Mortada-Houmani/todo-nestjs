# ==============================================================================
# outputs.tf — Expose key resource attributes after `terraform apply`.
#
# Run `terraform output` to print these values without re-applying.
# ==============================================================================

output "cloudfront_url" {
  description = "Public URL of the React frontend served by CloudFront."
  value       = "https://${module.cloudfront.domain_name}"
}

output "alb_dns" {
  description = "DNS name of the Application Load Balancer (backend API)."
  value       = module.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository. Use this in the GitHub Actions deploy workflow."
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "Hostname of the RDS PostgreSQL instance (private, reachable from ECS only)."
  value       = module.rds.endpoint
  sensitive   = true  # don't print in plain-text CI logs
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket that holds the frontend build artefacts."
  value       = module.frontend.bucket_id
}
