resource "aws_glue_catalog_database" "catalog" {
  name = local.name
}

resource "aws_glue_crawler" "crawler" {
  name          = "${local.name}-crawler"
  role          = var.crawler_role_arn
  database_name = aws_glue_catalog_database.catalog.name
  schedule      = var.crawler_schedule

  s3_target {
    path = var.s3_data_location
  }

  tags = local.common_tags
}

resource "aws_athena_workgroup" "athena" {
  name = local.name

  configuration {
    enforce_workgroup_configuration    = true

    result_configuration {
      output_location = var.athena_results_s3_uri

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = local.common_tags
}