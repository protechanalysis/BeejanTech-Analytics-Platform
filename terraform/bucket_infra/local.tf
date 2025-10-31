# Local values for more dynamic configuration
locals {

  bucket = var.bucket
  name   = var.name

  # Common tags to be applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Application = local.name
  }

  s3_tags = merge(local.common_tags, {
    Type = "Storage"
  })
}
