variable "project" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }

output "alb_sg_id" { value = aws_security_group.alb.id }
output "ecs_sg_id" { value = aws_security_group.ecs.id }
output "rds_sg_id" { value = aws_security_group.rds.id }
