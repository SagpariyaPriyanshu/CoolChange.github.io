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

module "database" {
  source = "../../modules/database"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  private_subnet_ids          = module.networking.private_subnet_ids
  database_security_group_id  = module.networking.database_security_group_id
  backend_security_group_id   = module.networking.backend_security_group_id

  # engine_version, instance_class, allocated_storage, db_name, and
  # db_username all use the module's small/cheap dev defaults.
}