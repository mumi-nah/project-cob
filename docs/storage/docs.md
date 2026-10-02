# Storage

Creates an S3 bucket with encryption, versioning, and blocked public
access on by default. No additional configuration needed to get a secure bucket.

## Get started

```hcl
module "storage_example" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "example"
}
```

This is 4 resources: the bucket, versioning, encryption, and the public
access block. Versioning is on, and all public access is blocked, nothing further to configure for a standard, secure bucket.

`bucket_purpose` is just a naming label, it only affects the bucket's
name (`<project>-<environment>-<bucket_purpose>`), same idea as
`role_purpose` in the IAM module.

## Adding lifecycle rules

If objects need to transition to cheaper storage or expire over time, add
`lifecycle_rules`:

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

This adds 1 more resource: a single lifecycle configuration containing
all the rules you list. Add as many rule objects to the list as needed;
they all live inside that one resource, not one each.

## Turning off versioning

```hcl
  versioning_enabled = false
```

## Reference

**Required inputs:** 
`environment`, `bucket_purpose`

**Optional inputs:** 
`project_name` (default `"cob"`), 
`versioning_enabled` (default `true`), 
`lifecycle_rules` (default `[]`), 
`force_destroy` (default `false`), 
`tags` (default `{}`)

**Key outputs:** 
`bucket_id`, `bucket_arn`, `bucket_name`

> For full input/output types, security notes, and design decisions, see
> `modules/storage/README.md`.