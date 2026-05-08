# ==============================================================================
# modules/alb/main.tf
#
# Application Load Balancer — receives HTTPS requests from the internet and
# forwards them to healthy ECS Fargate tasks.
#
# Listeners:
#   Port 80  → redirect to HTTPS (301)
#   Port 443 → forward to ECS target group
# ==============================================================================

# ------------------------------------------------------------------------------
# ALB
# ------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false         # internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids  # must be public subnets

  # Enable access logs to S3 (optional — uncomment to enable)
  # access_logs {
  #   bucket  = "my-alb-logs-bucket"
  #   enabled = true
  # }

  tags = { Environment = var.environment }
}

# ------------------------------------------------------------------------------
# Target Group
# Health-checks the /health endpoint we added to NestJS.
# ECS registers/deregisters tasks automatically.
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "backend" {
  name        = "${var.project}-${var.environment}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"   # required for Fargate (tasks have an IP, not an EC2 ID)

  health_check {
    enabled             = true
    path                = "/api/health"    # must match the endpoint in NestJS
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"        # expect HTTP 200 OK
  }

  tags = { Environment = var.environment }
}

# ------------------------------------------------------------------------------
# HTTP Listener (Port 80)
# Redirects to HTTPS if a certificate is provided, otherwise forwards to backend.
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.certificate_arn == "" ? aws_lb_target_group.backend.arn : null
  }
}

# ------------------------------------------------------------------------------
# HTTPS Listener (Port 443)
# Created only if a valid ACM certificate is provided.
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

