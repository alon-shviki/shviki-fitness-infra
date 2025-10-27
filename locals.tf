# ============================================================
# locals.tf
# Summary:
# Defines project name, environment, and reusable tags.
# ============================================================
locals {
  project     = "shviki-fitness"
  environment = var.environment
  region      = var.region
  name_prefix = "${local.project}-${local.environment}"

  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
