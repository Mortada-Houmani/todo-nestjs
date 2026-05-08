# ==============================================================================
# modules/networking/main.tf
#
# Creates a production-grade VPC layout:
#   • 2 public subnets  — ALB, NAT Gateways
#   • 2 private subnets — ECS Fargate tasks, RDS
#
# Using two AZs gives us high-availability at minimal cost.
# ==============================================================================

# ------------------------------------------------------------------------------
# Data sources — look up the available AZs in the chosen region at plan time
# ------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true   # needed so RDS endpoint hostnames resolve
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Internet Gateway — gives the public subnets a route to the internet
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

# ------------------------------------------------------------------------------
# Public subnets (one per AZ)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true   # instances launched here get a public IP

  tags = {
    Name = "${var.project}-${var.environment}-public-${count.index + 1}"
  }
}

# ------------------------------------------------------------------------------
# Private subnets (one per AZ)
# ECS tasks and RDS live here — they can reach the internet via NAT but are
# not directly reachable from it.
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project}-${var.environment}-private-${count.index + 1}"
  }
}

# ------------------------------------------------------------------------------
# NAT resources (EIP + NAT Gateway) – commented out to stay within the free tier.
# If you need outbound internet for private subnets, you can replace this with a NAT **instance**
# (e.g., an EC2 t3.micro) and adjust the route tables accordingly.
# ------------------------------------------------------------------------------
# resource "aws_eip" "nat" {
#   count  = 2
#   domain = "vpc"
#
#   tags = {
#     Name = "${var.project}-${var.environment}-eip-${count.index + 1}"
#   }
# }
#
# resource "aws_nat_gateway" "main" {
#   count = 2
#
#   allocation_id = aws_eip.nat[count.index].id
#   subnet_id     = aws_subnet.public[count.index].id
#
#   tags = {
#     Name = "${var.project}-${var.environment}-nat-${count.index + 1}"
#   }
#
#   # The NAT Gateway must be created after the Internet Gateway
#   depends_on = [aws_internet_gateway.main]
# }



# ------------------------------------------------------------------------------
# Route tables
# ------------------------------------------------------------------------------

# Public route table — sends all traffic (0.0.0.0/0) to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rt-public"
  }
}

# Associate every public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route tables — each AZ routes 0.0.0.0/0 to its own NAT Gateway
# ------------------------------------------------------------------------------
# Private route tables that pointed to NAT gateways – commented out.
# If you later add a NAT **instance**, uncomment and replace `nat_gateway_id` with the
# instance's ENI ID (or use a default route to an Internet Gateway for full public access).
# ------------------------------------------------------------------------------
#resource "aws_route_table" "private" {
#  count  = 2
#  vpc_id = aws_vpc.main.id
#
#  route {
#    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.main[count.index].id
#  }
#
#  tags = {
#    Name = "${var.project}-${var.environment}-rt-private-${count.index + 1}"
#  }
#}


# ------------------------------------------------------------------------------
# Associate private subnets with the (now commented) private route tables – disabled.
# ------------------------------------------------------------------------------
#resource "aws_route_table_association" "private" {
#  count = 2
#
#  subnet_id      = aws_subnet.private[count.index].id
#  route_table_id = aws_route_table.private[count.index].id
#}

