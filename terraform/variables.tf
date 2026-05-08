# ==============================================================================
# variables.tf — All input variables with types, defaults, and descriptions.
#
# Override these values in terraform.tfvars (never commit that file to git).
# ==============================================================================

# ------------------------------------------------------------------------------
# Global
# ------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy all resources into."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Short project name used as a prefix on every resource name."
  type        = string
  default     = "todo"
}

variable "environment" {
  description = "Deployment environment tag (production, staging, dev)."
  type        = string
  default     = "production"
}

# ------------------------------------------------------------------------------
# Database
# ------------------------------------------------------------------------------
variable "db_name" {
  description = "Name of the PostgreSQL database to create inside RDS."
  type        = string
  default     = "todoapp"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance. Override in tfvars."
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Application secrets
# ------------------------------------------------------------------------------
variable "jwt_secret" {
  description = "Secret key used to sign JWT access tokens."
  type        = string
  sensitive   = true
}

variable "jwt_email_secret" {
  description = "Secret key used to sign email-verification JWT tokens."
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Mail (SMTP)
# ------------------------------------------------------------------------------
variable "mail_host" {
  description = "SMTP server hostname (e.g. smtp.gmail.com)."
  type        = string
  default     = "smtp.gmail.com"
}

variable "mail_port" {
  description = "SMTP server port."
  type        = number
  default     = 587
}

variable "mail_user" {
  description = "SMTP username / sender email address."
  type        = string
  sensitive   = true
}

variable "mail_pass" {
  description = "SMTP password or app-specific password."
  type        = string
  sensitive   = true
}

variable "mail_from" {
  description = "Display name + address used in the From header."
  type        = string
}

# ------------------------------------------------------------------------------
# Frontend / CDN
# ------------------------------------------------------------------------------
variable "acm_certificate_arn" {
  description = <<EOT
ARN of an ACM certificate valid for your domain.
CloudFront requires the cert to be in us-east-1, even if the rest of the
infrastructure is in another region.
EOT
  type        = string
  default     = ""   # leave empty to skip HTTPS on ALB / CloudFront
}

variable "frontend_domain_aliases" {
  description = "Custom domain names for the CloudFront distribution (e.g. [\"app.example.com\"])."
  type        = list(string)
  default     = []
}
