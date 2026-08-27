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
