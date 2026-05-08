# ==============================================================================
# modules/ecr/main.tf
#
# Amazon Elastic Container Registry — private Docker image repository.
# The GitHub Actions deploy workflow pushes images here; ECS pulls from here.
# ==============================================================================

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project}-backend"
  image_tag_mutability = "MUTABLE"   # allows re-tagging (e.g. moving 'latest')

  # Scan images for known vulnerabilities on every push
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project}-backend"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Lifecycle Policy
# Keep only the 10 most recent images to control storage costs.
# Production images tagged "v*" are kept indefinitely; untagged layers are
# pruned after 1 day.
# ------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
