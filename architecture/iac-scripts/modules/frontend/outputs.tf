# CNAME target for www.coolchange.me once the cert is validated.
output "cloudfront_domain_name" {
  description = "CloudFront's own AWS-assigned hostname"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID — needed later (Phase 9) to invalidate the cache after each deploy"
  value       = aws_cloudfront_distribution.frontend.id
}

output "bucket_name" {
  description = "S3 bucket name — needed later (Phase 9) as the sync target for frontend deploys"
  value       = aws_s3_bucket.frontend.id
}

# Copy these into Namecheap as a new CNAME record, same as Phase 6.
output "certificate_validation_record_name" {
  description = "CNAME record name to add in Namecheap for ACM domain validation"
  value       = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_name
}

output "certificate_validation_record_value" {
  description = "CNAME record value to add in Namecheap for ACM domain validation"
  value       = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_value
}
