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

  private_subnet_ids         = module.networking.private_subnet_ids
  database_security_group_id = module.networking.database_security_group_id
  backend_security_group_id  = module.networking.backend_security_group_id

  # engine_version, instance_class, allocated_storage, db_name, and
  # db_username all use the module's small/cheap dev defaults.
}

module "compute" {
  source = "../../modules/compute"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  public_subnet_ids         = module.networking.public_subnet_ids
  backend_security_group_id = module.networking.backend_security_group_id
  alb_security_group_id     = module.networking.alb_security_group_id

  instance_profile_name = module.iam.backend_instance_profile_name
  backend_role_name     = module.iam.backend_role_name

  # instance_type, app_port, and admin_cidr_blocks all use the module's
  # defaults — revisit app_port once the backend framework is settled.
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  alb_security_group_id      = module.networking.alb_security_group_id
  backend_security_group_id  = module.networking.backend_security_group_id

  backend_instance_id = module.compute.instance_id

  domain_name = local.backend_domain_name

  # app_port and health_check_path use the module's defaults — same
  # app_port placeholder as the compute module, health_check_path is
  # "/" until confirmed with the BE lead.
}

module "frontend" {
  source = "../../modules/frontend"

  # Hands this module both AWS connections: the default one (for S3 and
  # CloudFront, which aren't region-scoped) and the us_east_1-aliased one
  # from provider.tf (required for the ACM certificate). The module's own
  # configuration_aliases declaration in acm.tf is what makes it able to
  # accept this second one at all.
  providers = {
    aws            = aws
    aws.us_east_1  = aws.us_east_1
  }

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  domain_name = "www.${local.domain_name}"
}