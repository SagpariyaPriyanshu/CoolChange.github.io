# Populated as later phases' modules expose values (VPC ID, subnet IDs,
# RDS endpoint, ALB DNS name, etc.) that dependent resources or the
# CI/CD pipeline need to reference. Empty at Phase 0 by design.

# Phase 6 — needed to add the DNS validation CNAME in Namecheap, and to
# eventually point api.coolchange.me at the ALB.
#
# Renamed with a backend_/frontend_ prefix now that Phase 7 adds a second
# certificate — without the prefix, both modules would try to produce an
# output with the same name, which Terraform doesn't allow at the root.
output "alb_dns_name" {
  description = "ALB's AWS-assigned hostname — CNAME target for api.coolchange.me"
  value       = module.loadbalancer.alb_dns_name
}

output "backend_certificate_validation_record_name" {
  description = "CNAME record name to add in Namecheap for the backend (api.coolchange.me) ACM validation"
  value       = module.loadbalancer.certificate_validation_record_name
}

output "backend_certificate_validation_record_value" {
  description = "CNAME record value to add in Namecheap for the backend (api.coolchange.me) ACM validation"
  value       = module.loadbalancer.certificate_validation_record_value
}

# Phase 7 — same idea, for the frontend's certificate and CDN.
output "cloudfront_domain_name" {
  description = "CloudFront's AWS-assigned hostname — CNAME target for www.coolchange.me"
  value       = module.frontend.cloudfront_domain_name
}

output "frontend_certificate_validation_record_name" {
  description = "CNAME record name to add in Namecheap for the frontend (www.coolchange.me) ACM validation"
  value       = module.frontend.certificate_validation_record_name
}

output "frontend_certificate_validation_record_value" {
  description = "CNAME record value to add in Namecheap for the frontend (www.coolchange.me) ACM validation"
  value       = module.frontend.certificate_validation_record_value
}