# ==============================================================================
# main.tf — Root module: wires together all sub-modules
# ==============================================================================

# Configure the AWS provider. Region and credentials come from variables so
# this file never contains secrets.
provider "aws" {
  region = var.aws_region
}

# --------------------------------------------------------------------------
# Networking — VPC, subnets, gateways, route tables
# --------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
}

# --------------------------------------------------------------------------
# Security Groups — controls inbound/outbound traffic per service
# --------------------------------------------------------------------------
module "security_groups" {
  source = "./modules/security_groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
}

# --------------------------------------------------------------------------
# RDS — managed PostgreSQL database in a private subnet
# --------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  project            = var.project
  environment        = var.environment
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.networking.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
}

# --------------------------------------------------------------------------
# ECR — private Docker image registry for the backend container
# --------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  project     = var.project
  environment = var.environment
}

# --------------------------------------------------------------------------
# ECS — Fargate cluster, task definition, and service for the backend
# --------------------------------------------------------------------------
module "ecs" {
  source = "./modules/ecs"

  project            = var.project
  environment        = var.environment
  aws_region         = var.aws_region
  ecr_image_url      = module.ecr.repository_url
  database_url       = module.rds.database_url
  jwt_secret         = var.jwt_secret
  jwt_email_secret   = var.jwt_email_secret
  frontend_url       = "https://${module.cloudfront.domain_name}"
  mail_host          = var.mail_host
  mail_port          = var.mail_port
  mail_user          = var.mail_user
  mail_pass          = var.mail_pass
  mail_from          = var.mail_from
  subnet_ids         = module.networking.public_subnet_ids
  ecs_sg_id          = module.security_groups.ecs_sg_id
  target_group_arn   = module.alb.target_group_arn
}


# --------------------------------------------------------------------------
# ALB — Application Load Balancer routes HTTPS traffic to ECS tasks
# --------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

# --------------------------------------------------------------------------
# S3 + CloudFront — static hosting for the React frontend
# --------------------------------------------------------------------------
module "frontend" {
  source = "./modules/frontend"

  project     = var.project
  environment = var.environment
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project             = var.project
  environment         = var.environment
  s3_bucket_id        = module.frontend.bucket_id
  s3_bucket_domain    = module.frontend.bucket_regional_domain
  alb_dns_name        = module.alb.dns_name
  acm_certificate_arn = var.acm_certificate_arn # must be in us-east-1 for CloudFront
  aliases             = var.frontend_domain_aliases
}
