variable "project-name" {
    description = "Short project/platform identifier used in resource naming"
    type = string
}

variable "environment" {
    description = "Environment name: dev, prod, etc"
    type = string
}

variable "tags" {
    descricption = "Common tags applied to all resources"
    type = map(string)
    default = {}
}

variable "vpc-cidr" {
    descricption = "CIDR Range for the vpc"
    type = string
}

variable "available-zones" {
    descricption = "List of AZs to spread subnets accross"
    type = list(string)
}
variable "public-subnet-cidrs" {
    descricption "CIDR Range for public subnets, one per AZ"
    type = list(string)
}

variable "private-subnet-cidrs" {
    description = "CIDR Range for private subnets, one per AZ"
    type = list(string)
}

variable "enable-enable_nat_gateway" {
    descricption = "Whether to provision NAT gateway(s) for private subnet egress"
    type = bool
    default = true
}

variable "single-nat-gateway" {
    descricption = "Use one NAT gateway for all AZs (cheaper, less resilient) instead of one per AZ"
    type = bool
    default = true
}

variable "instance_tenancy" {
    description = "specifies the tenancy to type to use for the resource (EC2)"
    type = string
    default = default
}