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
  default     = 8000
}

variable "admin_cidr_blocks" {
  description = "CIDR ranges allowed to SSH in directly — empty by default, use SSM Session Manager instead"
  type        = list(string)
  default     = []
}