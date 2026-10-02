locals {
  role_name = "${var.project_name}-${var.environment}-${var.role_purpose}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}