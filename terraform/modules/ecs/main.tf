# ==============================================================================
# modules/ecs/main.tf
#
# Runs the NestJS backend as a serverless container on AWS Fargate.
#
# Resources created:
#   • ECS Cluster
#   • IAM roles (execution + task)
#   • CloudWatch Log Group
#   • Task Definition (container spec, env vars, resource limits)
#   • ECS Service (keeps N copies of the task running behind the ALB)
# ==============================================================================

# ------------------------------------------------------------------------------
# ECS Cluster
# Fargate clusters have no EC2 instances to manage — AWS handles the compute.
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  # Enable Container Insights for CloudWatch metrics (CPU, memory per task)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Environment = var.environment }
}

# ------------------------------------------------------------------------------
# IAM — Execution Role
# Grants ECS the permissions it needs to pull the image from ECR and write
# logs to CloudWatch on behalf of your task.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach the AWS managed policy — covers ECR pull + CloudWatch Logs
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# IAM — Task Role
# The role assumed by the running container itself.
# Add additional policies here if the app needs S3, SQS, etc.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# Stores stdout/stderr from the NestJS container.
# Logs expire after 30 days to keep costs low.
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project}-${var.environment}-backend"
  retention_in_days = 30

  tags = { Environment = var.environment }
}

# ------------------------------------------------------------------------------
# Task Definition
# Describes the container: image, CPU/memory, port mapping, env vars, logging.
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-${var.environment}-backend"
  network_mode             = "awsvpc"    # required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"       # 0.25 vCPU — increase if needed
  memory                   = "512"       # MB

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "backend"
    image = "${var.ecr_image_url}:latest"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    # All secrets passed as environment variables (not baked into the image)
    environment = [
      { name = "NODE_ENV",         value = "production" },
      { name = "PORT",             value = "3000" },
      { name = "DATABASE_URL",     value = var.database_url },
      { name = "JWT_SECRET",       value = var.jwt_secret },
      { name = "JWT_EMAIL_SECRET", value = var.jwt_email_secret },
      { name = "FRONTEND_URL",     value = var.frontend_url },
      { name = "MAIL_HOST",        value = var.mail_host },
      { name = "MAIL_PORT",        value = tostring(var.mail_port) },
      { name = "MAIL_USER",        value = var.mail_user },
      { name = "MAIL_PASS",        value = var.mail_pass },
      { name = "MAIL_FROM",        value = var.mail_from },
    ]

    # Send logs to CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    # Container-level health check — ECS marks tasks unhealthy if this fails
    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://localhost:3000/api/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60  # seconds to wait before starting health checks
    }
  }])
}

# ------------------------------------------------------------------------------
# ECS Service
# Keeps the desired number of task replicas running.
# Registers new tasks with the ALB target group before removing old ones
# (rolling deployment with zero downtime).
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "backend" {
  name            = "${var.project}-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1       # increase to 2+ for production high-availability
  launch_type     = "FARGATE"

  # Rolling update settings — replace at most 100%, keep at least 100% healthy
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true   # Required for internet access without a NAT Gateway
  }


  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = 3000
  }

  # Ensure IAM role policy is attached before service creation
  depends_on = [aws_iam_role_policy_attachment.ecs_execution]

  tags = { Environment = var.environment }
}
