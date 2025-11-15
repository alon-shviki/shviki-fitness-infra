# ============================================================
# Summary:
# One-time script to create the S3 bucket used as Terraform remote backend.
# Uses AWS provider v5 resources for versioning & SSE.
# ============================================================

###############################################################
# Summary: S3 Bucket for Terraform State
# Description:
# This resource creates the S3 bucket that will store the
# terraform.tfstate file. This allows for a remote, shared,
# and secure backend for the infrastructure state.
###############################################################
resource "aws_s3_bucket" "tfstate" {
  # The unique name for the S3 bucket (e.g., "shviki-fitness-prod-tfstate")
  bucket = "${local.name_prefix}-tfstate"
  
  # Apply global project tags (e.g., "Environment=prod")
  tags   = local.tags
}

###############################################################
# Summary: S3 Bucket Versioning Configuration
# Description:
# Enables versioning on the Terraform state bucket. This is a
# critical safety feature that keeps a history of all state
# files, protecting against accidental deletions or corruption.
###############################################################
resource "aws_s3_bucket_versioning" "tfstate" {
  # The ID of the S3 bucket to configure
  bucket = aws_s3_bucket.tfstate.id
  
  versioning_configuration {
    # Set the versioning status to "Enabled"
    status = "Enabled"
  }
}

###############################################################
# Summary: S3 Bucket Server-Side Encryption (SSE)
# Description:
# Enforces server-side encryption on all objects written to the
# state bucket. This ensures that your terraform.tfstate file,
# which may contain sensitive data, is always encrypted at rest
# using AWS-managed AES256 encryption.
###############################################################
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  # The ID of the S3 bucket to configure
  bucket = aws_s3_bucket.tfstate.id
  
  rule {
    apply_server_side_encryption_by_default {
      # Use AES256, the AWS-managed encryption standard
      sse_algorithm = "AES256"
    }
  }
}