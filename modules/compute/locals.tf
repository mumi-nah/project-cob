locals {
  instance_name = "${var.project_name}-${var.environment}-${var.instance_purpose}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}