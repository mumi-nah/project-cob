# COB

Internal, reusable Terraform platform for provisioning standardised AWS
infrastructure across Beejan Technologies' engineering teams.

## What COB is

COB is a Terraform based internal platform, not a collection of files for
individual resources. It gives engineering teams reusable modules to
provision AWS infrastructure with consistent naming, tagging, and
security defaults built in, without needing to understand or rebuild the
underlying resources themselves.

## The problem it solves

Before COB, teams asked Platform Engineering for infrastructure, and it
was provisioned manually or with one off Terraform per request. That led
to inconsistent configurations, some buckets versioned and some not,
inconsistent IAM policies, and no shared naming or tagging. It was slow,
and hard to track changes across projects.

COB moves the org from "we need infrastructure, can Platform Engineering
build it" to "we provision what we need using the company's standard
platform."

## Available capabilities

- `networking`: VPC, public and private subnets, internet gateway, NAT
  gateway, baseline security group
- `iam`: one role per workload identity (EC2, ECS, Lambda), with explicit
  permissions and no wildcards by default
- `storage`: S3 buckets with encryption, versioning, and blocked public
  access on by default
- `compute/ecs`: not yet built, deferred
- `database`: RDS instances with generated credentials in Secrets
  Manager, and access limited to specific security groups
- `data-platform`: Glue Data Catalog and Athena, for querying data
  already sitting in S3

## How modules are consumed

Each module lives under `modules/<name>` and gets called from an
environment's root config:

```hcl
module "networking" {
  source = "../../modules/networking"

  environment = "dev"
}
```

Consuming teams should not need to read a module's internal resources,
just its own README for inputs and outputs. See `examples/` for a working
composition of more than one module together.

## Repository structure

- `modules/`: reusable platform capabilities, no environment specific
  values, this is the actual product
- `environments/`: per environment root configs, real values, real state,
  each with its own backend and AWS profile so dev can never touch prod
- `examples/`: example consumers, proving the modules are actually
  reusable together
- `docs/`: architecture notes and decisions

## Supported environments

`dev` and `prod`, each with fully isolated Terraform state and separate
AWS profiles. The same module code runs in both, only input values
differ, for example `single_nat_gateway` in networking, or `multi_az` in
database.

## Security considerations

- Every module defaults to secure behaviour rather than relying on the
  consuming team to remember it: encryption on by default, public access
  blocked by default in storage, least privilege IAM with no wildcards,
  database access limited to named security groups instead of CIDR
  blocks.
- Credentials are never stored in Terraform config. Database passwords
  are generated and kept in Secrets Manager.
- Environment isolation is structural, separate state and separate
  credentials, not just a naming convention.

## Assumptions

- Teams authenticate to AWS through SSO profiles, not long lived access
  keys.
- One VPC per environment for v1.
- IPv4 only across all modules.

## Design decisions

- Some security settings have no on and off variable at all: public
  access block in storage, encryption in storage and database, root
  volume encryption in compute/ec2. Every other toggle in this platform
  is optional, these are not, since the risk of someone flipping them off
  by accident outweighs the flexibility.
- `environment` has no default in any module, it must be passed
  explicitly every time, so a run can never silently default to `dev`
  naming or tags.
- IAM's `trusted_service` is a closed, validated list rather than a free
  string, extended deliberately as real needs come up, for example adding
  `glue.amazonaws.com` when the data-platform module needed it.
