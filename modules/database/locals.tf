locals {
  db_name = "${var.project_name}-${var.environment}-${var.db_purpose}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}