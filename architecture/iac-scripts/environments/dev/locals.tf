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

  # Registered via GitHub Student Developer Pack (Namecheap). One place
  # to change it — both the loadbalancer module (Phase 6) and the
  # frontend module (Phase 7) build their subdomains off this.
  domain_name         = "coolchange.me"
  backend_domain_name = "api.${local.domain_name}"

  # New in Phase 9 — identifies the repo GitHub Actions is allowed to
  # deploy from (used in the iam module's OIDC trust policy) and the
  # SSH clone URL the backend instance's boot script pulls from. One
  # place to change either if the repo is ever renamed or transferred.
  github_org          = "SagpariyaPriyanshu"
  github_repo         = "CoolChange.github.io"
  github_repo_ssh_url = "git@github.com:${local.github_org}/${local.github_repo}.git"
}