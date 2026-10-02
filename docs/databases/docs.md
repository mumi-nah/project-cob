# Database (RDS)

Creates an RDS instance in existing private subnets, with a generated
password in Secrets Manager and access locked down to specific security
groups.

## Get started

```hcl
module "database_example" {
  source = "../../modules/database"

  environment        = "dev"
  db_purpose         = "example"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  engine         = "postgres"
  engine_version = "16.3"
}
```

This builds a database with encryption on, 7-day backups, no standby
replica, and a security group with zero inbound rules, nothing can reach
it yet. The password is generated automatically and stored in Secrets
Manager, never in your Terraform config.

`db_purpose` is a naming label only, same idea as `role_purpose` and
`bucket_purpose` from earlier modules.

## Letting something connect to it

Pass the security group ID of whatever needs access, an EC2 instance or
ECS task built with this platform's other modules:

```hcl
  allowed_security_group_ids = [module.ec2_test.security_group_id]
```

Add more IDs to the list if more than one thing needs to connect.

## Getting the password

Never a Terraform output. Fetch it from Secrets Manager:

```bash
aws secretsmanager get-secret-value --secret-id <secret_arn> --query SecretString --output text
```

That returns `{"username":..., "password":..., "engine":...}` as JSON.
In a real app, the app itself fetches this at connection time instead of
a human pulling it manually.

## Making it resilient for prod

```hcl
  multi_az                = true
  backup_retention_period = 14
```

`multi_az = false` is the sensible default for dev — cheaper, and a
failover replica isn't worth the cost while testing.

## Reference

**Required inputs:** `environment`, `db_purpose`, `vpc_id`,
`private_subnet_ids`, `engine`, `engine_version`

**Optional inputs:** `project_name` (default `"cob"`),
`allowed_security_group_ids` (default `[]`), `instance_class` (default
`"db.t3.micro"`), `allocated_storage` (default `20`), `master_username`
(default `"dbadmin"`), `multi_az` (default `false`),
`backup_retention_period` (default `7`), `deletion_protection` (default
`true`), `skip_final_snapshot` (default `false`), `tags` (default `{}`)

**Key outputs:** `db_endpoint`, `db_port`, `secret_arn`

> For full input/output types and design decisions, see
> `modules/database/README.md`.