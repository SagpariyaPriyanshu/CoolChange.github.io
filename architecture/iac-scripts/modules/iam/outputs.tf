# Values Phase 4 (backend compute) needs — the EC2 instance gets created
# with this instance profile attached, giving it the role's permissions.

output "backend_role_arn" {
  description = "ARN of the backend EC2 role"
  value       = aws_iam_role.backend.arn
}

output "backend_role_name" {
  description = "Name of the backend EC2 role — needed by later phases that attach additional policies (e.g. Phase 5's SSM access)"
  value       = aws_iam_role.backend.name
}

output "backend_instance_profile_name" {
  description = "Name of the instance profile Phase 4's EC2 instance will attach"
  value       = aws_iam_instance_profile.backend.name
}

# New in Phase 9 — the environment layer wires these into the GitHub
# Actions workflow YAML files (as the `role-to-assume` input for the
# official aws-actions/configure-aws-credentials action), so each
# workflow authenticates as the right role for what it does.

output "github_actions_deploy_role_arn" {
  description = "ARN of the narrow CI role used by the frontend/backend deploy workflows"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_terraform_role_arn" {
  description = "ARN of the broader CI role used by the terraform plan/apply workflow"
  value       = aws_iam_role.github_actions_terraform.arn
}
