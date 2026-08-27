# Phase 1 onward wires modules in here, e.g.:
#
# module "networking" {
#   source      = "../../modules/networking"
#   name_prefix = local.name_prefix
#   common_tags = local.common_tags
# }
#
# Left empty at Phase 0 so `terraform plan` runs cleanly with zero
# resources before any actual AWS infrastructure is added.
