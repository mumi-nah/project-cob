locals {
  name = "${var.project_name}_${var.environment}_${var.data_platform_purpose}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}