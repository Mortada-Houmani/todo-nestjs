# ==============================================================================
# modules/rds/main.tf
#
# Managed PostgreSQL on Amazon RDS.
# The instance lives in a private subnet group and is reachable only from
# ECS tasks via the rds_sg security group.
# ==============================================================================

# ------------------------------------------------------------------------------
# Subnet Group — tells RDS which private subnets it may place replicas in.
# Using two subnets (two AZs) satisfies the Multi-AZ requirement.
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# RDS Instance
# ------------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-postgres"

  # Engine
  engine         = "postgres"
  engine_version = "15"                # match the version used locally in Docker

  # Compute & storage
  instance_class        = "db.t4g.micro"  # cheapest Graviton instance; upgrade for production load
  allocated_storage     = 20              # GB — auto-scales up to max_allocated_storage
  max_allocated_storage = 100
  storage_type          = "gp3"           # gp3 is cheaper than gp2 for small workloads
  storage_encrypted     = true            # encrypt at rest with AWS-managed key

  # Credentials — pulled from variables, never hardcoded
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false   # never expose the DB to the internet

  # Backups — Disabled for strict Free Tier compliance (increase to 1+ if needed)
  backup_retention_period = 0

  backup_window           = "03:00-04:00"   # UTC, low-traffic window
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Deletion protection — prevents accidental `terraform destroy` from dropping the DB
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project}-${var.environment}-final-snapshot"

  tags = {
    Name        = "${var.project}-${var.environment}-postgres"
    Environment = var.environment
  }
}
