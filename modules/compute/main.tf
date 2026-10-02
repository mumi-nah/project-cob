data "aws_ami" "amazon_linux" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  resolved_ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux[0].id
}

resource "aws_security_group" "security_group" {
  name_prefix       = "${local.instance_name}-"
  description       = "Security group for ${local.instance_name}"
  vpc_id            = var.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.security_group.id

  cidr_ipv4   = each.value.cidr_blocks[0]
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
  description = each.value.description
}

resource "aws_instance" "instance" {
  ami                    = local.resolved_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.security_group.id]
  iam_instance_profile   = var.instance_profile_name
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = local.instance_name
  })
}