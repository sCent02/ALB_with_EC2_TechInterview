# 1. The URL of your Load Balancer (This is what you'll visit in your browser)
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.alb.dns_name
}

# 2. The Public IPs of your 2 EC2 instances (to verify they are running)
output "ec2_public_ips" {
  description = "The public IP addresses of the EC2 instances"
  value       = aws_instance.app_server[*].public_ip
}

# 3. The Target Group ARN (often required in exam documentation)
output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = aws_lb_target_group.tg.arn
}