# Lets GitHub Actions authenticate to AWS by exchanging a short-lived
# OIDC token for temporary AWS credentials — no long-lived AWS access
# keys need to be stored as a GitHub secret. One provider, shared by
# both CI roles below.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # AWS stopped actually validating this value against GitHub's real
  # certificate back in 2022 — IAM now checks against its own trusted
  # root CA list instead — but the API still requires a syntactically
  # valid 40-character value here. Captured directly from GitHub's own
  # OIDC endpoint (token.actions.githubusercontent.com) rather than a
  # hardcoded/remembered value, to be certain it's actually correct.
  thumbprint_list = ["227203b5317f3818cab5b5ce596132bf36748c0e"]

  tags = var.common_tags
}

# Declared here rather than in variables.tf since they're only used by
# this file — identifies exactly which repo is allowed to assume the
# roles below. No default: must be set explicitly by whoever calls this
# module, so a typo can't accidentally trust the wrong repo.
variable "github_org" {
  description = "GitHub org/username that owns the repo, e.g. SagpariyaPriyanshu"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name, e.g. CoolChange.github.io"
  type        = string
}

# Discovered in Phase 9, after the repo was transferred to a new owner:
# GitHub doesn't always issue the sub claim as the plain
# "repo:OWNER/REPO:..." string this trust policy originally assumed.
# Around a rename or ownership transfer, it issues an ID-suffixed form
# instead — "repo:OWNER@OWNER_ID/REPO@REPOSITORY_ID:..." — appending
# each side's immutable numeric ID. This is deliberate on GitHub's part:
# it stops a trust policy written for an old name from silently matching
# a *different* repo that later reclaims that name. Confirmed live by
# decoding this repo's actual OIDC token (see Architecture Decisions
# Log). These IDs are permanent for this repo regardless of any future
# rename, so hardcoding them here is safe — unlike the org/repo name
# above, there's no "typo the wrong repo" risk, since a real ID doesn't
# collide with anyone else's.
variable "github_owner_id" {
  description = "GitHub's immutable numeric ID for the repo owner (from the OIDC token's sub claim) — needed because GitHub issues an ID-suffixed sub format after an ownership transfer"
  type        = string
  default     = "56132067"
}

variable "github_repo_id" {
  description = "GitHub's immutable numeric ID for the repo itself (from the OIDC token's sub claim) — see github_owner_id"
  type        = string
  default     = "1330385399"
}

# Trust policy shared by both CI roles: only workflow runs from this
# exact repo (any branch/PR/tag — narrowing further isn't necessary,
# since each role's own *permissions*, not its trust policy, are what
# actually limit blast radius) are allowed to assume them. Two patterns
# are listed (StringLike accepts multiple values, OR'd together) so this
# keeps working whether GitHub issues the plain sub format or the
# ID-suffixed one — see the variables above for why both exist.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:*",
        "repo:${var.github_org}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}:*",
      ]
    }
  }
}

# Narrow role for the deploy workflows (frontend sync, backend SSM
# trigger) — permissions attached in ci_deploy_policy.tf.
resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.name_prefix}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = var.common_tags
}

# Broader role for terraform plan/apply — permissions attached in
# ci_terraform_policy.tf.
resource "aws_iam_role" "github_actions_terraform" {
  name               = "${var.name_prefix}-github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = var.common_tags
}