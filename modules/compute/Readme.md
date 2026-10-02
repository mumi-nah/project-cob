# compute/ec2

Launches an EC2 instance into an existing subnet, with a security group
scoped to only the access it actually needs, an encrypted root volume,
and an IAM instance profile attached if one's passed in.

## What it does

- Launches one EC2 instance
- Creates a security group for it, built entirely from the inbound rules
  you pass in, nothing open by default
- Auto-selects the latest Amazon Linux 2023 AMI if you don't specify one
- Attaches an IAM instance profile if you give it one
- Encrypts the root volume, always
- Names and tags everything consistently
- Creates no key pair, access is meant to go through SSM, not SSH

## How to use it

Basic instance, no inbound access, managed through SSM:

```hcl
module "ec2_example" {
  source = "../../modules/compute/ec2"

  environment            = "dev"
  instance_purpose       = "example"
  vpc_id                 = module.networking.vpc_id
  subnet_id              = module.networking.private_subnet_ids[0]
  instance_profile_name  = module.iam_ssm_access.instance_profile_name
}
```

With an inbound rule:

```hcl
module "ec2_with_ingress" {
  source = "../../modules/compute/ec2"

  environment      = "dev"
  instance_purpose = "web"
  vpc_id           = module.networking.vpc_id
  subnet_id        = module.networking.public_subnet_ids[0]

  ingress_rules = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

See `docs.md` for the full walkthrough from minimal to more.

## Requirements

- terraform >= 1.5.0
- aws provider ~> 6.0

## Inputs

- `environment` (string, required) : environment name (`dev`, `staging`, `prod`)
- `instance_purpose` (string, required) : what this instance is for, used in naming
- `vpc_id` (string, required) — VPC ID for the security group, from the networking module
- `subnet_id` (string, required) : subnet to launch into, from the networking module
- `project_name` (string, default `"cob"`) : project identifier used in naming
- `instance_profile_name` (string, default `null`) : instance profile to attach, from the iam module
- `instance_type` (string, default `"t3.micro"`)
- `ami_id` (string, default `null`) : leave empty to auto-select the latest Amazon Linux 2023 AMI
- `ingress_rules` (list(object), default `[]`) : each with `description`, `from_port`, `to_port`, `protocol`, `cidr_blocks`
- `root_volume_size` (number, default `20`)
- `associate_public_ip` (bool, default `false`)
- `tags` (map(string), default `{}`)

## Outputs

- `instance_id`
- `private_ip`
- `public_ip` — `null` unless `associate_public_ip` is `true`
- `security_group_id`

## Assumptions

- The subnet and VPC already exist, this module doesn't create
  networking, it consumes it.
- One instance, one purpose. Call the module again for a different
  instance instead of reusing one.

## Design decisions

- No key pair is created for this instance. Access is expected to go
  through SSM Session Manager (via an attached instance profile with the
  right permissions), not SSH with a stored key.
- Root volume encryption has no on/off variable, it's always applied,
  same reasoning as the public access block in storage.
- `environment` has no default, same as every other module, forces a
  real choice so a run can't silently default to `dev` naming.
- `ingress_rules` defaults to empty, an instance needs zero inbound
  access unless a consumer explicitly asks for it.

## Future improvements

- Support for launch templates / auto scaling groups, for workloads that
  need more than a single fixed instance.
- Optional EBS data volumes beyond the root volume.