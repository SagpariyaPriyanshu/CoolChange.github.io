# The security groups themselves were created in Phase 1 as empty shells
# with zero rules in either direction. This is where the actual database
# access rule gets added — as its own standalone resource, not by editing
# the Phase 1 security_groups.tf file.

# Allow the backend to reach the database on the Postgres port.
resource "aws_vpc_security_group_ingress_rule" "db_from_backend" {
  security_group_id            = var.database_security_group_id
  referenced_security_group_id = var.backend_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "Allow Postgres from the backend only"
}

# The other half of the same connection: since both security groups
# started with zero rules in Phase 1, the backend also needs explicit
# permission to send traffic OUT to the database, not just the database
# needing permission to receive it.
resource "aws_vpc_security_group_egress_rule" "backend_to_db" {
  security_group_id            = var.backend_security_group_id
  referenced_security_group_id = var.database_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "Allow outbound Postgres to the database only"
}
