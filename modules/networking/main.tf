resource "aws_vpc" "vpc" {
  cidr_block             = var.vpc_cidr
  enable_dns_hostnames   = true
  enable_dns_support     = true
  instance_tenancy = "default"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count                       = length(var.public_subnet_cidrs)
  vpc_id                      = aws_vpc.vpc.id
  cidr_block                  = var.public_subnet_cidrs[count.index]
  availability_zone           = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count                       = length(var.private_subnet_cidrs)
  vpc_id                      = aws_vpc.vpc.id
  cidr_block                  = var.private_subnet_cidrs[count.index]
  availability_zone           = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "eip" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "ngw" {
  count           = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  allocation_id   = aws_eip.eip[count.index].id
  subnet_id       = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  count = length(var.private_subnet_cidrs)

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index}"
  })
}

resource "aws_route" "private-route" {
  count                       = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  route_table_id              = aws_route_table.private[count.index].id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id               = var.single_nat_gateway ? aws_nat_gateway.ngw[0].id : aws_nat_gateway.ngw[count.index].id
}

resource "aws_route_table_association" "private" {
  count             = length(var.private_subnet_cidrs)
  subnet_id         = aws_subnet.private[count.index].id
  route_table_id    = aws_route_table.private[count.index].id
}

resource "aws_security_group" "default" {
  name_prefix      = "${local.name_prefix}-default-"
  description      = "Default baseline SG - no ingress, all egress"
  vpc_id           = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-default-sg"
  })
}