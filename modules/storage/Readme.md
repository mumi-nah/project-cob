# storage

Creates an S3 bucket with encryption, versioning, and blocked public
access set up automatically, so nobody has to remember to configure these
correctly every time a bucket is needed.

## What it does

- Creates one S3 bucket
- Turns on versioning (default: on, can be turned off)
- Encrypts objects with SSE-S3 (AES256)
- Blocks all public access, always
- Adds lifecycle rules if you pass any in
- Names and tags everything consistently

## How to use it

Basic bucket:

```hcl
module "storage_example" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "example"
}
```

With lifecycle rules:

```hcl
module "storage_with_lifecycle" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "with-lifecycle"

  lifecycle_rules = [
    {
      id                       = "archive-old-data"
      prefix                   = "raw/"
      transition_days          = 90
      transition_storage_class = "GLACIER"
      expiration_days          = 365
    }
  ]
}
```

See `docs.md` for the full walkthrough from minimal to more.

## Requirements

- terraform >= 1.5.0
- aws provider ~> 6.0

## Inputs

- `environment` (string, required) — environment name (`dev`, `staging`, `prod`)
- `bucket_purpose` (string, required) — what this bucket is for, used in naming
- `project_name` (string, default `"cob"`) — project identifier used in naming
- `versioning_enabled` (bool, default `true`) — enable object versioning
- `lifecycle_rules` (list(object), default `[]`) — list of lifecycle rules, each with `id`, `prefix`, `transition_days`, `transition_storage_class`, `expiration_days`
- `force_destroy` (bool, default `false`) — allow bucket deletion even with objects inside
- `tags` (map(string), default `{}`) — extra tags merged into every resource

## Outputs

- `bucket_id` : bucket ID
- `bucket_arn` : bucket ARN
- `bucket_name` : bucket name
- `bucket_domain_name` : regional domain name, for building URLs

## Assumptions

- Bucket names are globally unique across all AWS accounts, not just
  ours — naming collisions during testing can happen.
- One bucket, one purpose. Call the module again for a different bucket
  instead of reusing one.

## Design decisions

- Public access block has no on/off variable — it's always applied.
  Every other module has toggles for security-relevant settings, but a
  public bucket should be a conscious exception someone builds outside
  this module, not a flag flipped by accident.
- `environment` has no default, same as networking and iam — forces a
  real choice so a run can't silently default to `dev` naming.

## Future improvements

- SSE-KMS support, for teams that need customer-managed keys and a
  CloudTrail audit trail on encrypt/decrypt.
- Access logging to a target bucket, for auditing who accessed what and
  when.