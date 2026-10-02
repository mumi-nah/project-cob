output "glue_database_name" {
  value = aws_glue_catalog_database.catalog.name
}

output "crawler_name" {
  value = aws_glue_crawler.crawler.name
}

output "athena_workgroup_name" {
  value = aws_athena_workgroup.athena.name
}