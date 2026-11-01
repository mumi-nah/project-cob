# database

Creates a managed RDS instance in existing private subnets, reachable
only from security groups you explicitly allow, with a generated master
password stored in Secrets Manager instead of anywhere in Terraform
config.

## What it does

- Creates one RDS instance
- Creates a DB subnet group from the subnets you pass in
- Creates a security group that only trusts specific security groups you
  list, never a CIDR block
- Generates a random master password and stores it in Secrets Manager
- Encrypts storage, always
- Takes daily backups, retained for 7 days by default
- Names and tags everything consistently
- Never outputs the password directly

## How to use it

Needs subnets from `networking`, and (if you want anything to actually
connect to it) a security group ID from something like `compute/ec2`:

```hcl
module "database_test" {
  source = "../../modules/database"

  environment        = "dev"
  db_purpose         = "test"
  vpc_id             = module.cob_network.vpc_id
  private_subnet_ids = module.cob_network.private_subnet_ids

  allowed_security_group_ids = [module.compute_test.security_group_id]

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"
}
```

Without `allowed_security_group_ids`, the database still builds fine —
it just has no inbound rules, so nothing can reach it. Fine for proving
the module works, not useful for actually connecting.

### Getting the password

The password is never a Terraform output. Pull it from Secrets Manager
after apply:

```bash
aws secretsmanager get-secret-value --secret-id <secret_arn> --query SecretString --output text | jq -r .password
```

In real usage, the application itself calls Secrets Manager at
connection time, it doesn't get baked into config anywhere. Whatever's
doing the fetching needs `secretsmanager:GetSecretValue` on that secret's
ARN.

See `docs.md` for the full walkthrough from minimal to more.

## Requirements

- terraform >= 1.5.0
- aws provider ~> 6.0
- random provider ~> 3.6

## Inputs

- `environment` (string, required) : environment name (`dev`, `staging`, `prod`)
- `db_purpose` (string, required) : what this database is for, used in naming
- `vpc_id` (string, required) : from the networking module
- `private_subnet_ids` (list(string), required) : at least 2, from the networking module
- `engine` (string, required) : `postgres` or `mysql`
- `engine_version` (string, required)
- `project_name` (string, default `"cob"`) : project identifier used in naming
- `allowed_security_group_ids` (list(string), default `[]`) : security groups allowed to connect
- `instance_class` (string, default `"db.t3.micro"`)
- `allocated_storage` (number, default `20`)
- `master_username` (string, default `"dbadmin"`)
- `multi_az` (bool, default `false`) : standby replica in a second AZ, for prod
- `backup_retention_period` (number, default `7`)
- `deletion_protection` (bool, default `true`)
- `skip_final_snapshot` (bool, default `false`) : keep false outside of throwaway test databases
- `tags` (map(string), default `{}`)

## Outputs

- `db_instance_id`
- `db_endpoint`
- `db_port`
- `secret_arn` — Secrets Manager ARN holding username, password, engine
- `security_group_id`

## Assumptions

- Subnets and VPC already exist : this module doesn't create networking,
  it consumes it.
- Whatever needs to connect already has its own security group, this
  module only references that group's ID, it doesn't create it.

## Design decisions

- No `master_password` variable exists. The password is generated inside
  the module and stored in Secrets Manager, never typed by you or a human,
  never in a `.tfvars` file.
- Access is granted by security group, not CIDR block. The database only
  trusts specific, named security groups, same reasoning as everything
  else in this platform that touches network access.
- `storage_encrypted` has no variable, same as encryption in every other
  module — always on.
- `environment` has no default, same as every module, forces a real
  choice so a run can't silently default to `dev` naming.
- `deletion_protection` defaults to `true` — a database is the one
  resource in this platform where an accidental destroy is the most
  expensive kind of mistake.

## Future improvements

- Read replicas, for workloads that need to scale reads separately.
- Custom parameter groups, for engine tuning beyond the defaults.
- Automatic password rotation via Secrets Manager's rotation feature.