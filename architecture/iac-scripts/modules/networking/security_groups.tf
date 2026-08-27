# Security group shells only — created here so later phases (compute,
# database, load balancer) can reference their IDs, but deliberately
# left with zero rules for now.
#
# Important: creating an aws_security_group with no inline ingress/egress
# blocks results in a group with ZERO rules in both directions — Terraform
# actively removes AWS's automatic "allow all outbound" default when no
# egress block is declared. That's intentional default-deny here, not an
# oversight. Each later phase adds only the specific rule it owns, as a
# separate standalone rule resource (aws_vpc_security_group_ingress_rule /
# aws_vpc_security_group_egress_rule) — not by editing this file — which
# is the current recommended pattern over inline rule blocks.

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Application Load Balancer (rules added in Phase 5)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "backend" {
  name_prefix = "${var.name_prefix}-backend-"
  description = "Backend EC2 instance(s) (rules added in Phase 4)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-db-"
  description = "RDS database (rules added in Phase 3)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
