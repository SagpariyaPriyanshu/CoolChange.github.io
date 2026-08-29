variable "name_prefix" {
  description = "Prefix for resource names, e.g. coolchange-dev"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to every resource this module creates"
  type        = map(string)
  default     = {}
}

# One entry per secret you want in Secrets Manager, keyed by a short
# name (e.g. "heat-data-api-key") and mapped to its actual value. Empty
# by default — add a real entry here later and one secret gets created
# automatically, no new Terraform files needed.
#
# NOT marked sensitive here — Terraform won't allow a sensitive value's
# keys to drive a for_each (the keys could leak into resource addresses
# in plan output). The actual values stay protected anyway: the AWS
# provider marks aws_secretsmanager_secret_version's secret_string field
# sensitive at the resource level, so it still prints as
# "(sensitive value)" in plan/apply output regardless of this variable.
variable "app_secrets" {
  description = "Map of secret name => secret value, for anything beyond the DB credentials (Phase 3 handles those separately)"
  type        = map(string)
  default     = {}
}