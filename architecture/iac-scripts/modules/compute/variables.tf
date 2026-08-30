variable "name_prefix" {
  description = "Prefix for resource names, e.g. coolchange-dev"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to every resource this module creates"
  type        = map(string)
  default     = {}
}

# From the networking module (Phase 1)
variable "public_subnet_ids" {
  description = "Public subnet IDs — the backend runs in one of these"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Security group ID for the backend instance"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for the load balancer — the only thing allowed to reach the backend on app_port"
  type        = string
}

# From the iam module (Phase 2)
variable "instance_profile_name" {
  description = "IAM instance profile to attach, from the iam module"
  type        = string
}

variable "backend_role_name" {
  description = "Name of the backend IAM role, from the iam module — needed to attach the SSM policy in this phase"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance size — x86_64 family for broad software compatibility"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the backend application listens on"
  type        = number
  default     = 3000

  # Was 8000 (a guess) through Phases 5-8. The real backend scaffold
  # (Node/Express) defaults to 3000 — confirmed by inspecting the actual
  # code in Phase 9, rather than guessing further.
}

variable "admin_cidr_blocks" {
  description = "CIDR ranges allowed to SSH in directly — empty by default, use SSM Session Manager instead"
  type        = list(string)
  default     = []
}

# New in Phase 9 — everything the user_data bootstrap script needs to
# install Node, pull the backend code, and wire it up to the database.
variable "github_repo_ssh_url" {
  description = "SSH clone URL for the private backend repo, e.g. git@github.com:org/repo.git"
  type        = string
}

variable "deploy_key_secret_arn" {
  description = "Secrets Manager ARN holding the read-only GitHub deploy key, from the secrets module"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB connection info, from the database module — the instance reads this at boot to build its DATABASE_URL"
  type        = string
}

variable "aws_region" {
  description = "Region to pass to the AWS CLI calls inside user_data (the instance's IAM role provides credentials, but the CLI still needs to be told which region)"
  type        = string
}
