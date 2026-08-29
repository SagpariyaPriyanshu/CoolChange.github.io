# Looks up the latest Ubuntu 22.04 (Jammy) AMI rather than hardcoding an
# AMI ID — AMI IDs are region-specific and change whenever Canonical
# publishes a new patched image, so hardcoding one would go stale.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS publishing account —
                                  # restricting to this prevents accidentally
                                  # picking a similarly-named lookalike AMI

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.backend_security_group_id]
  iam_instance_profile   = var.instance_profile_name

  # Needed for outbound internet access via the internet gateway, since
  # there's no NAT gateway. Inbound access is still fully controlled by
  # the security group (file 3), not by whether a public IP exists.
  associate_public_ip_address = true

  # Renders templates/user_data.sh.tpl with these values substituted in,
  # then runs the result once on first boot. Changing user_data forces
  # Terraform to replace the instance (a new one boots with the new
  # script) rather than editing it in place — AWS doesn't support
  # re-running user_data on a live instance.
  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    aws_region             = var.aws_region
    repo_ssh_url            = var.github_repo_ssh_url
    deploy_key_secret_arn  = var.deploy_key_secret_arn
    db_secret_arn          = var.db_secret_arn
    app_port                = var.app_port
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend"
  })
}