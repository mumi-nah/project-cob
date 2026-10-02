# The COB Networking module

Engineering teams or network teams have reasons to provision networks or vpc, this module standardizes that process.

## What does this module do?: 
It Provisions a standard VPC with public and private subnets spread across multiple AZs per user's specification, an Internet Gateway for public egress, and optional NAT Gateway(s) for private subnet egress. 

## What a consumer must tell it:
A user should specify their project environment (for naming), how big the VPC should be (CIDR), how many AZs to spread across, and whether they need NAT (and how cheaply — one NAT for the whole VPC, or one per AZ for resilience).

## What a consumer gets back:
the VPC ID, the list of public subnet IDs, the list of private subnet IDs, and the NAT gateway IDs — so their compute or database module can say "put this in the private subnets" without knowing how those subnets were built.