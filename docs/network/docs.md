# Networking

Provisions a VPC with public and private subnets, internet access for both
tiers, and a baseline security group — the network foundation other COB
modules build on.

## How it works

Public subnets route outbound traffic through an Internet Gateway. Private
subnets route outbound traffic through a NAT Gateway, so resources inside
them can reach the internet (for updates, API calls, etc.) without being
reachable *from* the internet.

## Get started

`environment` is the only required input — everything else has a sensible
default.

```hcl
module "networking" {
  source = "../../modules/networking"

  environment = "dev"
}
```

This creates a `10.0.0.0/16` VPC, spread across 2 auto-detected AZs in your
current region, with public and private subnets sized automatically. NAT
Gateway egress for private subnets is on by default.

> **Why `environment` has no default:** it's required on purpose, so a
> deployment can never silently default to `dev` naming/tags if you forget
> to set it — see the module README for the full rationale.

Use the outputs to wire other modules to this network:

```hcl
module "compute" {
  source = "../../modules/compute"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
}
```

## Spreading across more AZs

To use more than the default 2 AZs, set `az_count` — subnet CIDRs are still
derived automatically:

```hcl
module "networking" {
  source = "../../modules/networking"

  environment = "prod"
  az_count    = 3
}
```

## Overriding AZs or CIDRs explicitly

If you need specific AZs or specific subnet sizing instead of the
auto-derived defaults, set them directly — this takes priority over
`az_count` and auto-derivation:

```hcl
module "networking" {
  source = "../../modules/networking"

  environment           = "prod"
  vpc_cidr              = "10.1.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
}
```

## Controlling NAT Gateway cost vs. resilience

By default, the module creates one NAT Gateway per AZ. For non-production
environments where a NAT outage is acceptable, use a single shared NAT
Gateway instead to reduce cost:

```hcl
module "networking" {
  source = "../../modules/networking"
  # ...

  single_nat_gateway = true
}
```

To disable NAT entirely (private subnets with no internet egress at all):

```hcl
  enable_nat_gateway = false
```

## Adding tags

```hcl
  tags = {
    Owner = "platform-engineering"
  }
```
Tags here are merged with the module's own naming/tagging — you don't need
to repeat `Project` or `Environment`, those are set automatically.

## Reference

**Required inputs:** `environment`

**Optional inputs:** `project_name` (default `"cob"`), `vpc_cidr` (default
`"10.0.0.0/16"`), `az_count` (default `2`), `availability_zones` (default:
auto-detected), `public_subnet_cidrs` / `private_subnet_cidrs` (default:
auto-derived from `vpc_cidr`), `enable_nat_gateway` (default `true`),
`single_nat_gateway` (default `false`), `tags` (default `{}`)

**Key outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`,
`nat_gateway_ids`, `default_security_group_id`

> For the full input/output reference and security notes, see
> `modules/networking/README.md`.