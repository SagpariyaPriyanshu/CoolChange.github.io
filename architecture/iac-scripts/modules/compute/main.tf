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

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend"
  })
}
