# Values Phase 4 (backend compute) needs — the EC2 instance gets created
# with this instance profile attached, giving it the role's permissions.

output "backend_role_arn" {
  description = "ARN of the backend EC2 role"
  value       = aws_iam_role.backend.arn
}

output "backend_instance_profile_name" {
  description = "Name of the instance profile Phase 4's EC2 instance will attach"
  value       = aws_iam_instance_profile.backend.name
}
