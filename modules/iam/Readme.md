# iam

Creates one IAM role per workload identity — EC2, ECS task, or Lambda —
with a trust policy scoped to that service and permissions built only from
what's explicitly listed. No wildcard actions, nothing implicit.

## What this module does

- Creates one `aws_iam_role`, with a trust policy scoped to a single
  AWS service principal (`trusted_service`)
- Optionally builds a custom permissions policy from an explicit list of
  statements (`policy_statements`) and attaches it to the role
- Optionally attaches one or more AWS-managed policies
  (`managed_policy_arns`)
- Creates an `aws_iam_instance_profile` automatically, only when
  `trusted_service = "ec2.amazonaws.com"` — EC2 can't reference a role
  directly, everything else can
- Applies consistent naming (`<project>-<environment>-<role_purpose>`)
  and tagging

## What it does NOT do

- Does not create roles humans assume (SSO/console access) — service
  roles only
- Does not support cross-account trust or SAML/OIDC principals
- Does not support permissions boundaries
- Does not create the resources being granted access to (S3 buckets, RDS
  instances, etc.) — this module only handles identity and permissions

## How to use it

One call = one role. Call it once per identity you need — e.g. an ECS
workload needs it called twice, once for the execution role and once for
the task role.

```hcl
module "iam_app_role" {
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

Reference the outputs from other modules or resources:

```hcl
resource "aws_ecs_task_definition" "app" {
  # ...
  task_role_arn = module.iam_app_role.role_arn
}
```

See `docs.md` for a full walkthrough building up from the minimal case.

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| aws provider | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `environment` | Environment name (`dev`, `staging`, `prod`) | `string` | – | yes |
| `role_purpose` | Short identifier for what this role is for, used in naming | `string` | – | yes |
| `trusted_service` | AWS service principal that assumes this role — `ec2.amazonaws.com`, `ecs-tasks.amazonaws.com`, or `lambda.amazonaws.com` | `string` | – | yes |
| `project_name` | Short project/platform identifier used in resource naming | `string` | `"cob"` | no |
| `policy_statements` | Explicit IAM policy statements — `sid`, `actions`, `resources` per entry | `list(object)` | `[]` | no |
| `managed_policy_arns` | AWS-managed policy ARNs to attach | `list(string)` | `[]` | no |
| `tags` | Additional tags merged into every resource's tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN of the created role |
| `role_name` | Name of the created role |
| `instance_profile_name` | Instance profile name — only set when `trusted_service = "ec2.amazonaws.com"`, otherwise `null` |

## Security considerations

- No `policy_statements` entry should use `"*"` for `resources` unless
  there's genuinely no way to scope it — this module doesn't block
  wildcards, it just doesn't encourage them by not defaulting to any.
- Managed policies are AWS-maintained and sometimes broader than strict
  least privilege — know what a managed policy actually grants before
  attaching it (check the policy in IAM, not just the name).
- `trusted_service` is validated against a closed list on purpose — see
  Design decisions below.

## Assumptions

- One role serves one purpose. Don't reuse a single role across unrelated
  workloads just to save a module call — call the module again instead.
- ECS callers know they need two separate calls (execution + task role),
  not one.

## Known limitations

- `trusted_service` only supports `ec2.amazonaws.com`,
  `ecs-tasks.amazonaws.com`, `lambda.amazonaws.com`. Extend the validation
  list deliberately when a real need arises (e.g. RDS enhanced monitoring's
  `monitoring.rds.amazonaws.com`) — don't open it up preemptively.
- No cross-account or human-assumable role support — out of scope for v1.

## Design decisions

- **`environment` has no default** — same reasoning as the networking
  module: forces an explicit choice per apply, so a run can never
  silently default to `dev` naming/tags.
- **`trusted_service` is a closed, validated list, not a free string** —
  a typo'd service principal is syntactically valid to AWS and creates a
  role nothing can ever assume, with no error until something tries to use
  it. The validation trades some flexibility for catching that at `plan`
  time.
- **Custom policy uses a standalone `aws_iam_policy` + attachment, not an
  inline policy (`aws_iam_role_policy`)** — kept consistent with how
  managed policies attach (same pattern for both), and standalone
  policies are independently visible/auditable in IAM rather than buried
  inside the role.
- **Instance profile creation is conditional, not always-on** — only EC2
  needs one; creating it for every role would leave orphaned, unused
  objects for Lambda/ECS.