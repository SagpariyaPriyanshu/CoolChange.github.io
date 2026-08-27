module "networking" {
  source = "../../modules/networking"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  # vpc_cidr and availability_zones both use the module's defaults
  # (10.0.0.0/16, ap-southeast-4a/4b) — override here later if dev ever
  # needs something different.
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}