variable "project" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "ecr_image_url" { type = string }
variable "database_url" {
  type      = string
  sensitive = true
}
variable "jwt_secret" {
  type      = string
  sensitive = true
}
variable "jwt_email_secret" {
  type      = string
  sensitive = true
}
variable "frontend_url" { type = string }
variable "mail_host" { type = string }
variable "mail_port" { type = number }
variable "mail_user" {
  type      = string
  sensitive = true
}
variable "mail_pass" {
  type      = string
  sensitive = true
}
variable "mail_from" { type = string }
variable "subnet_ids" { type = list(string) }
variable "ecs_sg_id" { type = string }
variable "target_group_arn" { type = string }

output "cluster_name" { value = aws_ecs_cluster.main.name }
output "service_name" { value = aws_ecs_service.backend.name }

