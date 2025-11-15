# ============================================================
# Summary:
# Defines project name, environment, and reusable tags.
# Description:
# This file defines local variables used for consistent naming
# and tagging across all resources in the project. It centralizes
# the project name, environment, and constructs prefixed names
# and a standard tag map to ensure uniformity.
# ============================================================

###############################################################
# Summary: Centralized Local Variables
# Description:
# Defines all common local variables. Using locals ensures that
# values like the project name or environment prefix are
# consistent across the entire Terraform configuration.
###############################################################
locals {
  # Base name for the entire project
  project     = "shviki-fitness"
  
  # The deployment environment (e.g., "prod") from an input variable
  environment = var.environment
  
  # The AWS region for deployment (e.g., "eu-west-1") from an input variable
  region      = var.region
  
  # Standard prefix for most resources (e.g., "shviki-fitness-prod")
  name_prefix = "${local.project}-${local.environment}"
  
  # Specific, unique name for the EKS cluster
  eksname     = "${local.name_prefix}-eks"

  # A reusable map of tags to apply to all taggable AWS resources
  tags = {
    Project     = local.project     # Tag with the project name
    Environment = local.environment # Tag with the deployment environment
    ManagedBy   = "Terraform"       # Tag to show this resource is managed by IaC
  }
}