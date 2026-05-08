variable "project" { type = string }
variable "environment" { type = string }
variable "db_name" { type = string }
variable "db_username" {
  type      = string
  sensitive = true
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "private_subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }

output "endpoint" {
  description = "Hostname of the RDS instance (without port)."
  value       = aws_db_instance.main.address
}

output "database_url" {
  description = "Full PostgreSQL connection string for NestJS / TypeORM."
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/${var.db_name}"
  sensitive   = true
}

