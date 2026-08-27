locals {
  project = "coolchange"

  # Applied to every resource in this environment via the provider's
  # default_tags (see provider.tf) — nothing created from Phase 1
  # onward needs to tag itself manually.
  common_tags = {
    Project     = local.project
    Iteration   = "1"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Naming convention for resources created by modules going forward:
  # ${local.name_prefix}-<resource>, e.g. coolchange-dev-vpc,
  # coolchange-dev-rds, coolchange-dev-alb.
  name_prefix = "${local.project}-${var.environment}"
}
