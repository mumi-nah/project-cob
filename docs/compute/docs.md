# Compute (EC2)

Launches an EC2 instance into an existing subnet, with a locked-down
security group and an encrypted root volume by default.

## Get started

```hcl
module "ec2_example" {
  source = "../../modules/compute/ec2"

  environment      = "dev"
  instance_purpose = "example"
  vpc_id           = module.networking.vpc_id
  subnet_id        = module.networking.private_subnet_ids[0]
}
```

This is 2 resources: the instance and its security group. No inbound
access, no public IP, root volume encrypted, latest Amazon Linux 2023 AMI
auto-selected. There's no key pair, access is meant to go through SSM.

`instance_purpose` is a naming label only, same idea as `role_purpose`
and `bucket_purpose` in the earlier modules.

## Attaching an IAM role

Pass an instance profile from the iam module to give the instance
permissions:

```hcl
  instance_profile_name = module.iam_ssm_access.instance_profile_name
```

## Opening inbound access

By default the security group has no inbound rules at all. Add what you
actually need:

```hcl
  ingress_rules = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
```

Add as many rule objects as needed, they all land in the same security
group.

## Using a specific AMI or instance size

```hcl
  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t3.small"
```

Leave `ami_id` unset to keep auto-selecting the latest Amazon Linux 2023
AMI on every apply.

## Reference

**Required inputs:** `environment`, `instance_purpose`, `vpc_id`, `subnet_id`

**Optional inputs:** `project_name` (default `"cob"`),
`instance_profile_name` (default `null`), `instance_type` (default
`"t3.micro"`), `ami_id` (default `null`), `ingress_rules` (default `[]`),
`root_volume_size` (default `20`), `associate_public_ip` (default
`false`), `tags` (default `{}`)

**Key outputs:** `instance_id`, `private_ip`, `security_group_id`

> For full input/output types and design decisions, see
> `modules/compute/ec2/README.md`.