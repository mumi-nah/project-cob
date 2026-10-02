# IAM

Creates one IAM role for one workload identity — EC2, ECS task, or Lambda
— with permissions built only from what you explicitly list.

## How it works

Every role needs two things: a trust policy (who's allowed to assume it)
and permissions (what it can do once assumed). This module only creates
what your inputs actually call for — no permissions means no policy
object gets created, and only EC2 gets an instance profile.

## Get started

The smallest possible call — just an identity, no permissions yet:

```hcl
module "iam_example" {
  source = "../../modules/iam"

  environment     = "dev"
  role_purpose    = "example"
  trusted_service = "lambda.amazonaws.com"
}
```

This is 1 resource — the role itself. Nothing else gets created until you
ask for it.

`role_purpose` is just a label for what this role is for — it only feeds
into the role's name (`<project>-<environment>-<role_purpose>`), so you
can tell roles apart when you've called this module many times.

## Giving it permissions

Add `policy_statements` to grant specific actions on specific resources:

```hcl
module "iam_example" {
  source = "../../modules/iam"

  environment     = "dev"
  role_purpose    = "app-role"
  trusted_service = "ecs-tasks.amazonaws.com"

  policy_statements = [
    {
      sid       = "ReadAppBucket"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::my-app-bucket", "arn:aws:s3:::my-app-bucket/*"]
    }
  ]
}
```

Now you get 4 resources — the role, a policy built from your statements,
and the attachment connecting them. Add as many statement objects to the
list as you need; they all land in the same policy, not separate ones.

## Attaching AWS-managed policies

For common cases, skip writing your own statements and attach an existing
AWS-managed policy instead:

```hcl
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
```

Add as many ARNs as needed — one attachment per ARN.

## EC2 roles get an instance profile for free

EC2 can't use a role directly — it needs an instance profile wrapping it.
Set `trusted_service = "ec2.amazonaws.com"` and this module creates one
automatically:

```hcl
module "iam_ssm_access" {
  source = "../../modules/iam"

  environment         = "dev"
  role_purpose        = "ssm-access"
  trusted_service     = "ec2.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}
```

Attach `module.iam_ssm_access.instance_profile_name` to your instance. For
any other `trusted_service`, this output is just `null`.

## ECS needs two calls, not one

An ECS task has two identities: the execution role (ECS agent pulls the
image, writes logs) and the task role (your app's own permissions). Call
the module twice:

```hcl
module "iam_ecs_execution" {
  source              = "../../modules/iam"
  environment         = "dev"
  role_purpose        = "ecs-execution"
  trusted_service     = "ecs-tasks.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

module "iam_ecs_task" {
  source          = "../../modules/iam"
  environment     = "dev"
  role_purpose    = "ecs-task"
  trusted_service = "ecs-tasks.amazonaws.com"

  policy_statements = [
    {
      sid       = "ReadAppBucket"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::my-app-bucket/*"]
    }
  ]
}
```

## Reference

**Required inputs:** `environment`, `role_purpose`, `trusted_service`

**Optional inputs:** `project_name` (default `"cob"`), `policy_statements`
(default `[]`), `managed_policy_arns` (default `[]`), `tags` (default `{}`)

**Key outputs:** `role_arn`, `role_name`, `instance_profile_name`

> For full input/output types, security notes, and design decisions, see
> `modules/iam/README.md`.