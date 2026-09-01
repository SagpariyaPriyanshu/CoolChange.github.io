# Values later phases need — Phase 6's load balancer will target this
# instance by its ID, and the public/private IPs are useful for direct
# reference (e.g. connecting via SSM) without digging through the console.

output "instance_id" {
  description = "EC2 instance ID — the ALB target group (Phase 6) attaches to this"
  value       = aws_instance.backend.id
}

output "public_ip" {
  description = "Public IP of the backend instance"
  value       = aws_instance.backend.public_ip
}

output "private_ip" {
  description = "Private IP of the backend instance"
  value       = aws_instance.backend.private_ip
}
