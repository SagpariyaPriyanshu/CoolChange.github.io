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

# Phase 8 — the "app code wiring" half: everything Phase 9's CI/CD
# pipeline will need to know where to deploy to, gathered in one place
# instead of buried inside each module.
output "db_secret_arn" {
  description = "Secrets Manager ARN for the DB connection info — the backend reads its DB credentials from here at runtime"
  value       = module.database.db_secret_arn
}

output "backend_instance_id" {
  description = "EC2 instance ID the backend deploys to"
  value       = module.compute.instance_id
}

output "frontend_bucket_name" {
  description = "S3 bucket the frontend build gets synced into"
  value       = module.frontend.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed to invalidate the cache after each frontend deploy"
  value       = module.frontend.cloudfront_distribution_id
}

output "app_secret_arns" {
  description = "Map of app secret name to ARN, from the secrets module (empty until a real secret is added)"
  value       = module.secrets.secret_arns
}