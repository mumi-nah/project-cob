resource "aws_vpc" "vpc" {
  cidr_block             = var.vpc-cidr
  enable_dns_hostnames   = true
  enable_dns_support     = true
  instance_tenancy = "default"

  tags = merge(local.common_tags, {
    Name = '${local.name_prefix}-vpc'
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = '${local.name_prefix}-igw'
  })
}

resource "aws_subnet" "public" {
  count                       = length(var.public-subnet-cidrs)
  vpc_id                      = aws_vpc.vpc.id
  cidr_block                  = var.public-subnet-cidrs[count.index]
  availability_zones          = var.availability-zones[count.index]
  map_to_public_ip_on_launch  = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count                       = length(var.private-subnet-cidrs)
  vpc_id                      = aws_vpc.vpc.id
  cidr_block                  = var.private-subnet-cidrs[count.index]
  availability_zones          = var.availability-zones[count.index]

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
  route_table_id = aws_route_table.example.id
}

