# Generates a random password so no one has to invent (or remember) one.
resource "random_password" "db" {
  length  = 32
  special = true
  # RDS Postgres disallows /, @, ", and space in passwords — restricting
  # the special character set here so we never generate one RDS rejects.
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

# The secret "container" — just metadata (name, description). Named to
# start with "coolchange-dev/" so it matches the ARN pattern the backend's
# IAM policy (Phase 2) was already scoped to allow reading.
resource "aws_secretsmanager_secret" "db" {
  name_prefix = "${var.name_prefix}/db-"
  description = "Database connection info for ${var.name_prefix}"

  tags = var.common_tags
}

# The actual secret value — kept as a separate resource from the
# container above, so the value can be rotated/versioned later without
# recreating the secret itself. Stored as one JSON blob so the backend
# can read a single secret and get everything it needs to connect.
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db.result
  })
}
