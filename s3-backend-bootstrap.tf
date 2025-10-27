# ============================================================
# s3-backend-bootstrap.tf
# Summary:
# One-time script to create the S3 bucket used as Terraform remote backend.
# Uses AWS provider v5 resources for versioning & SSE.
# ============================================================

resource "aws_s3_bucket" "tfstate" {
  bucket = "${local.name_prefix}-tfstate"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
