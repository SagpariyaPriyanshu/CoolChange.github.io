# Populated as later phases' modules expose values (VPC ID, subnet IDs,
# RDS endpoint, ALB DNS name, etc.) that dependent resources or the
# CI/CD pipeline need to reference. Empty at Phase 0 by design.

# Phase 6 — needed to add the DNS validation CNAME in Namecheap, and to
# eventually point api.coolchange.me at the ALB.
output "alb_dns_name" {
  description = "ALB's AWS-assigned hostname — CNAME target for api.coolchange.me"
  value       = module.loadbalancer.alb_dns_name
}

output "certificate_validation_record_name" {
  description = "CNAME record name to add in Namecheap for ACM domain validation"
  value       = module.loadbalancer.certificate_validation_record_name
}

output "certificate_validation_record_value" {
  description = "CNAME record value to add in Namecheap for ACM domain validation"
  value       = module.loadbalancer.certificate_validation_record_value
}