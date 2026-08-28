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
variable "vpc_id" {
  description = "VPC ID — the ALB and its target group both need this"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs — the ALB itself runs across these"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "backend_security_group_id" {
  description = "Security group ID for the backend — the ALB needs an egress rule to reach it"
  type        = string
}

# From the compute module (Phase 5)
variable "backend_instance_id" {
  description = "EC2 instance ID to attach to the target group"
  type        = string
}

variable "app_port" {
  description = "Port the backend application listens on — must match the compute module's app_port"
  type        = number
  default     = 8000
}

# New for this phase
variable "domain_name" {
  description = "Full domain name the ALB serves, e.g. api.coolchange.me — the ACM certificate is issued for this exact name"
  type        = string
}

variable "health_check_path" {
  description = "Path the ALB hits to check the backend is healthy — placeholder until confirmed with the BE lead"
  type        = string
  default     = "/"
}
