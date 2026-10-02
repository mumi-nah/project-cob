# Data Platform (Glue/Athena)

Creates a Glue database and crawler for an S3 location, plus an Athena
workgroup ready to query it, with results locked to a specific location
and encrypted.

## Get started

```hcl
module "data_platform_example" {
  source = "../../modules/data-platform"

  environment            = "dev"
  data_platform_purpose  = "example"
  s3_data_location       = "s3://${module.storage_source.bucket_name}/raw/"
  crawler_role_arn       = module.iam_glue_crawler.role_arn
  athena_results_s3_uri  = "s3://${module.storage_results.bucket_name}/athena-results/"
}
```

This needs a source bucket and a results bucket from `storage`, and a
crawler role from `iam` with `trusted_service = glue.amazonaws.com`. See
`README.md` for the full example showing all three modules wired
together.

This is 3 resources: the Glue database, the crawler, and the Athena
workgroup. The crawler runs on demand until you set a schedule. Athena
results are encrypted and locked to the location you gave it, nobody
querying through this workgroup can point results anywhere else.

`data_platform_purpose` is a naming label, same idea as `bucket_purpose`
and `role_purpose` from earlier modules, though this one uses underscores
instead of hyphens since Glue does not accept hyphens in names.

## Running the crawler on a schedule

By default the crawler only runs when triggered manually. To run it
automatically:

```hcl
  crawler_schedule = "cron(0 6 * * ? *)"
```

That example runs it daily at 6am UTC.


## Reference

Required inputs: `environment`, `data_platform_purpose`,
`s3_data_location`, `crawler_role_arn`, `athena_results_s3_uri`

Optional inputs: `project_name` (default `"cob"`), `crawler_schedule`
(default `null`), `bytes_scanned_cutoff_per_query` (default `null`),
`tags` (default `{}`)

Key outputs: `glue_database_name`, `crawler_name`, `athena_workgroup_name`

For full input and output types and design decisions, see
`modules/data-platform/README.md`.