output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.ngw[*].id
}

output "default_security_group_id" {
  value = aws_security_group.default.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT gateways — useful for allow-listing on external services"
  value       = aws_eip.ngw[*].public_ip
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}