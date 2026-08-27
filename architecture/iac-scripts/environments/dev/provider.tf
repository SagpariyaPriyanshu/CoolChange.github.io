provider "aws" {
  region = var.region

  # Applied to every resource created in this environment from Phase 1
  # onward, so nothing needs to tag itself manually.
  default_tags {
    tags = local.common_tags
  }
}
