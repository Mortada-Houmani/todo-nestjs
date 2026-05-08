variable "project" { type = string }
variable "environment" { type = string }

output "bucket_id" { value = aws_s3_bucket.frontend.id }
output "bucket_regional_domain" { value = aws_s3_bucket.frontend.bucket_regional_domain_name }
