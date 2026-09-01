provider "aws" {
  region = var.region

  # Applied to every resource created in this environment from Phase 1
  # onward, so nothing needs to tag itself manually.
  default_tags {
    tags = local.common_tags
  }
}

# Second connection to AWS, pointed at us-east-1 instead of our normal
# region — exists only because CloudFront requires its certificate to be
# requested in us-east-1, no matter where everything else lives (Phase 7).
# The "alias" is what lets two provider "aws" blocks coexist; resources
# opt into this one with provider = aws.us_east_1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}