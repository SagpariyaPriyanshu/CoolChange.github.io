# Lets GitHub Actions authenticate to AWS by exchanging a short-lived
# OIDC token for temporary AWS credentials — no long-lived AWS access
# keys need to be stored as a GitHub secret. One provider, shared by
# both CI roles below.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # AWS stopped actually validating this value against GitHub's real
  # certificate back in 2022 — IAM now checks against its own trusted
  # root CA list instead — but the API still requires a value here.
  # This is GitHub's well-documented, stable thumbprint.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea"]

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

# Trust policy shared by both CI roles: only workflow runs from this
# exact repo (any branch/PR/tag — narrowing further isn't necessary,
# since each role's own *permissions*, not its trust policy, are what
# actually limit blast radius) are allowed to assume them.
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
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
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
