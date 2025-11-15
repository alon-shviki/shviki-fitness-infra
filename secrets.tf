###############################################################
# Summary: AWS Secrets Manager Secret
# Description:
# This resource creates the secret in AWS Secrets Manager that
# will hold all the application's sensitive values. It is
# explicitly encrypted using the EKS cluster's KMS key.
###############################################################
resource "aws_secretsmanager_secret" "shviki_secrets" {
  # The unique name (path) for the secret in Secrets Manager
  name = "shviki-fitness/prod/app-secrets"

  # Encrypts this secret using the EKS cluster's KMS key
  kms_key_id = module.eks.kms_key_arn

  # Apply global project tags
  tags = local.tags

  # This ensures the EKS key exists before creating the secret
  depends_on = [
    module.eks
  ]
}

###############################################################
# Summary: AWS Secrets Manager Secret Version
# Description:
# This resource populates the secret created above with the actual
# sensitive values (passwords, API keys). The values are pulled
# from the git-ignored 'secrets.auto.tfvars' file and stored
# as a single JSON string.
###############################################################
resource "aws_secretsmanager_secret_version" "shviki_secrets_version" {
  # The ID of the secret to populate
  secret_id = aws_secretsmanager_secret.shviki_secrets.id

  # This JSON object is built from your git-ignored secrets.auto.tfvars file
  secret_string = jsonencode({
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_USER          = var.mysql_user
    MYSQL_USER_PASSWORD = var.mysql_user_password
    MYSQL_DATABASE      = var.mysql_database
    FLASK_SECRET_KEY    = var.flask_secret_key
    RAPIDAPI_KEY        = var.rapidapi_key
  })
}