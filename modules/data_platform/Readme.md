# data-platform

Creates a Glue Data Catalog database and a crawler that scans an existing
S3 location to discover table schemas, plus an Athena workgroup
pre-configured to query that catalog with results written to a dedicated,
encrypted S3 location.

## What it does

- Creates one Glue Data Catalog database
- Creates a Glue crawler pointed at an S3 location you give it
- Creates an Athena workgroup with results locked to a specific S3 path
- Encrypts Athena query results, always
- Enforces the workgroup config so nobody can override the results
  location or turn off encryption per query
- Names everything with underscores, since Glue does not accept hyphens
  in database or table names

## How to use it

Needs a source data location and results location from `storage`, and a
crawler role from `iam` (trusted_service = glue.amazonaws.com):

```hcl
module "storage_source" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "source-data"
}

module "storage_results" {
  source = "../../modules/storage"

  environment    = "dev"
  bucket_purpose = "athena-results"
}

module "iam_glue_crawler" {
  source              = "../../modules/iam"
  environment         = "dev"
  role_purpose        = "glue-crawler"
  trusted_service     = "glue.amazonaws.com"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]

  policy_statements = [
    {
      sid       = "ReadSourceData"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = [module.storage_source.bucket_arn, "${module.storage_source.bucket_arn}/*"]
    }
  ]
}

module "data_platform_example" {
  source = "../../modules/data-platform"

  environment            = "dev"
  data_platform_purpose  = "example"
  s3_data_location       = "s3://${module.storage_source.bucket_name}/raw/"
  crawler_role_arn       = module.iam_glue_crawler.role_arn
  athena_results_s3_uri  = "s3://${module.storage_results.bucket_name}/athena-results/"
}
```

After apply, run the crawler once (console: Glue, Crawlers, Run), confirm
a table shows up in the Glue database, then query it from Athena using
the new workgroup.

See `docs.md` for the full walkthrough from minimal to more.

## Requirements

- terraform >= 1.5.0
- aws provider ~> 6.0

## Inputs

- `environment` (string, required): environment name (`dev`, `staging`, `prod`)
- `data_platform_purpose` (string, required): what this capability is for, used in naming
- `s3_data_location` (string, required): s3://bucket/prefix the crawler should scan
- `crawler_role_arn` (string, required): IAM role ARN the crawler assumes, from the iam module
- `athena_results_s3_uri` (string, required): s3://bucket/prefix where Athena writes results
- `project_name` (string, default `"cob"`): project identifier used in naming
- `crawler_schedule` (string, default `null`): cron expression for automatic crawler runs, leave null for on-demand only
- `bytes_scanned_cutoff_per_query` (number, default `null`): stop a query if it scans more than this many bytes
- `tags` (map(string), default `{}`)

## Outputs

- `glue_database_name`
- `crawler_name`
- `athena_workgroup_name`

## Assumptions

- Source data and results locations already exist in S3, created through
  the storage module.
- The crawler's IAM role already exists, created through the iam module
  with `trusted_service = glue.amazonaws.com`.

## Design decisions

- `enforce_workgroup_configuration` has no variable, same as encryption
  and public access block elsewhere in this platform: always on.
- Naming uses underscores instead of hyphens, since Glue rejects hyphens
  in database and table names. This is an intentional exception to the
  naming convention used everywhere else.
- `environment` has no default, same as every module: forces a real
  choice so a run cannot silently default to `dev` naming.
- Adding `glue.amazonaws.com` to the iam module's trusted_service list
  was a deliberate extension made when this module needed it, not a
  preemptive addition.

## Future improvements

- Support for multiple S3 targets in a single crawler.
- Glue jobs for actual data transformation, not just cataloging.
- Named Athena queries or saved query templates for common analytics use
  cases.