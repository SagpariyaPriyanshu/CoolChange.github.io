# The role the backend EC2 instance runs as. This only defines WHO can
# use the role (the trust policy, below) — WHAT it's allowed to actually
# do lives in policies.tf, kept separate on purpose.

resource "aws_iam_role" "backend" {
  name_prefix = "${var.name_prefix}-backend-"
  description = "Role assumed by the backend EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-role"
  })
}

# EC2 can't attach an IAM role to an instance directly — it attaches an
# "instance profile" instead, which is just a thin wrapper around exactly
# one role. This is what Phase 4's compute module will reference.
resource "aws_iam_instance_profile" "backend" {
  name_prefix = "${var.name_prefix}-backend-"
  role        = aws_iam_role.backend.name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-instance-profile"
  })
}
