# Values later phases need to reference — the database (Phase 3), backend
# compute (Phase 4), and load balancer (Phase 5) modules all take these as
# inputs rather than looking the networking layer up themselves.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancer goes here)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (database goes here)"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group ID for the load balancer"
  value       = aws_security_group.alb.id
}

output "backend_security_group_id" {
  description = "Security group ID for the backend EC2 instance(s)"
  value       = aws_security_group.backend.id
}

output "database_security_group_id" {
  description = "Security group ID for the RDS database"
  value       = aws_security_group.database.id
}
