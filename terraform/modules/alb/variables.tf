variable "project" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "certificate_arn" {
  type    = string
  default = ""
}

output "dns_name" { value = aws_lb.main.dns_name }
output "target_group_arn" { value = aws_lb_target_group.backend.arn }
