# ==============================================================================
# modules/security_groups/main.tf
#
# Three tiers of security groups implement the principle of least privilege:
#
#   alb_sg  — accepts HTTPS (443) from anywhere on the internet
#   ecs_sg  — accepts traffic only from the ALB
#   rds_sg  — accepts Postgres traffic only from ECS tasks
# ==============================================================================

# ------------------------------------------------------------------------------
# ALB Security Group
# Allows HTTP (80) and HTTPS (443) from the internet.
# HTTP is kept open so we can redirect it to HTTPS inside the ALB listener.
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Allow HTTP and HTTPS inbound from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet (redirected to HTTPS by ALB listener)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound — the ALB needs to forward traffic to ECS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-alb-sg" }
}

# ------------------------------------------------------------------------------
# ECS Security Group
# Only accepts traffic from the ALB on the container port (3000).
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "Allow inbound traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NestJS app port from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound (ECR image pulls, SMTP, RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-ecs-sg" }
}

# ------------------------------------------------------------------------------
# RDS Security Group
# Only accepts Postgres (5432) from ECS tasks.
# Locked down so the database is never directly reachable from the internet.
# ------------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL inbound from ECS tasks only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-${var.environment}-rds-sg" }
}
