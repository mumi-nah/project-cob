# PROJECT COB

Internal, reusable Terraform platform for provisioning standardised AWS
infrastructure across Beejan Technologies' engineering teams.

## What COB is

COB is a Terraform-based internal platform, not a collection of Terraform
files for individual resources. It provides reusable modules that
engineering teams consume to provision AWS infrastructure with consistent
naming, tagging, and security defaults built in — without needing to
understand or re-implement the underlying resources themselves.

## The problem it solves

Before COB, teams requested infrastructure from Platform Engineering, who
provisioned it manually or wrote one-off Terraform per request. This
created inconsistent configurations (some S3 buckets versioned, some not;
inconsistent IAM policies; varying naming/tagging), was slow, and made
changes hard to track across projects.

COB moves the org from *"we need infrastructure, can Platform Engineering
build it?"* to *"we provision what we need using the company's standard
platform."*

## Available capabilities

| Module | Status | What it provides |
|---|---|---|
| `networking` | Available | VPC, public/private subnets, IGW, NAT Gateway(s), baseline security group |
| `iam` | Planned | Reusable least-privilege IAM role/policy patterns |
| `storage` | Planned | Standardised, secure-by-default S3 buckets |
| `compute` | Planned | EC2 and ECS with sensible networking/IAM wired in |
| `database` | Planned | RDS with networking and security defaults |
| `data-platform` | Planned | S3 → Glue Data Catalog → Athena integration |

## How modules are consumed

Each module lives under `modules/<name>/` and is called from an
environment's root configuration:

```hcl
module "networking" {
  source = "../../modules/networking"

  project_name = "cob"
  environment  = "dev"
  # ... see modules/<name>/README.md for full inputs
}
```

Consuming teams should never need to read a module's internal resource
definitions — the inputs and outputs documented in each module's own
README are the full interface. See `examples/` for a working, realistic
composition of multiple modules.

## Repository structure

```
cob/
├── modules/          # Reusable platform capabilities (this is the product)
│   └── networking/
├── environments/     # Per-environment root configs — real values, real state
│   ├── dev/
│   └── prod/
├── examples/         # Example consumers proving the modules are reusable
└── docs/             # Architecture, decisions, diagrams
```

- **`modules/`** contains no hardcoded environment values — pure, reusable
  capability code.
- **`environments/`** is where actual infrastructure gets deployed. Each
  environment has its own state backend and its own AWS credentials/profile,
  so changes to `dev` can never affect `prod`.
- **`examples/`** demonstrates a realistic engineering team composing
  several COB modules together, not manually recreating AWS resources.

## Supported environments

`dev` and `prod`, each with fully isolated Terraform state (separate S3
backends) and separate AWS profiles. The same module code is reused across
both; only input values differ (see each module's README for
environment-relevant variables, e.g. `single_nat_gateway`).

## Security considerations

- Modules aim for secure-by-default configuration (private-by-default
  subnets, encryption at rest where applicable, least-privilege IAM
  patterns) rather than relying on consuming teams to remember to configure
  it themselves.
- Environment isolation is enforced structurally (separate state, separate
  credentials) rather than by convention alone.
- Module-specific security notes and known limitations are documented in
  each module's own README under `modules/<name>/README.md`.

## Important assumptions

- Consuming teams have AWS access configured via SSO profiles, not
  long-lived access keys.
- One VPC per environment is the assumed baseline topology for v1.
- IPv4-only across all modules in this version.

## Known limitations

- Custom NACLs are not implemented; the platform relies on default NACLs
  plus security groups for network-level access control.
- IPv6 is not currently supported.
- Only `networking` is implemented so far; other capabilities are planned
  (see table above) and will follow the same module conventions
  (`versions.tf` / `variables.tf` / `main.tf` / `outputs.tf` / `README.md`).

## Architectural decisions

Documented as they're made in `docs/decisions/` — starting with the
networking module's dev-vs-prod NAT Gateway trade-off (shared NAT for cost
in dev, one NAT per AZ for resilience in prod).