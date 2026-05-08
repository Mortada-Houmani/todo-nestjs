variable "project" { type = string }
variable "environment" { type = string }

output "repository_url" {
  description = "Full ECR image URL (without tag). Append :tag when pushing."
  value       = aws_ecr_repository.backend.repository_url
}
