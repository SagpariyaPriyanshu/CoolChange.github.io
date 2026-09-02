# A DB subnet group is required by RDS — it just tells RDS which subnets
# it's allowed to place the instance in (must span 2+ AZs, hence Phase 1
# creating 2 private subnets even though only 1 DB instance runs here).
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.name_prefix}-db-"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier_prefix = "${var.name_prefix}-"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  # random_password.db is declared in secrets.tf, not this file — that's
  # fine, Terraform resolves references across every file in a module
  # together, it doesn't matter which file something is physically in.
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]

  # Dev-appropriate choices, kept cheap and simple. Revisit all of these
  # for environments/prod/ in Phase 11 — prod would want multi_az = true,
  # deletion_protection = true, and a real backup retention period.
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
  deletion_protection     = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
