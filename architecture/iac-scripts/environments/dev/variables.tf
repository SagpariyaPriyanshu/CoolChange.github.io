variable "region" {
  description = "AWS region for this environment"
  type        = string
  default     = "ap-southeast-4"
}

variable "environment" {
  description = "Environment name (dev, staging, ...)"
  type        = string
  default     = "dev"
}

# Further variables (VPC CIDR, instance sizing, etc.) get added here as
# each phase's module is wired in — left minimal at Phase 0 on purpose.

# New in Phase 9 — the private half of the GitHub SSH key the backend
# instance uses to clone the repo at boot. No default, and marked
# sensitive so Terraform never prints it in plan/apply output. The
# actual value is never written in any committed file — it's supplied
# via a terraform.tfvars file, which .gitignore already excludes from
# version control.
#
# Currently holds a temporary personal-account SSH key (real deploy key
# access needs repo admin rights, which this account doesn't have yet)
# — swap the value in terraform.tfvars for the proper read-only deploy
# key once a teammate with admin access adds one, no other file changes
# needed.
variable "backend_deploy_key" {
  description = "Private SSH key (deploy key or, temporarily, a personal key) for cloning the private backend repo"
  type        = string
  sensitive   = true
}