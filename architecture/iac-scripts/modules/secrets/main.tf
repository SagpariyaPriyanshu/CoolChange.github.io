# One secret per entry in var.app_secrets. for_each over a map (rather
# than count, which is for lists) creates one resource per key, and
# each.key / each.value give you that entry's name and value inside the
# resource block — same for_each pattern used for the SSH rules back in
# Phase 5, just over a map instead of a list this time.
resource "aws_secretsmanager_secret" "app" {
  for_each = var.app_secrets

  name        = "${var.name_prefix}/${each.key}"
  description = "App secret: ${each.key}"

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "app" {
  for_each = var.app_secrets

  secret_id     = aws_secretsmanager_secret.app[each.key].id
  secret_string = each.value
}
