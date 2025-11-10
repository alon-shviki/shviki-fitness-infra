# FILE: shviki-fitness-infra/secrets.tf

resource "aws_secretsmanager_secret" "shviki_secrets" {
  name = "shviki-fitness/prod/app-secrets"

  kms_key_id = module.eks.kms_key_arn

  tags = local.tags

  # This ensures the EKS key exists before creating the secret
  depends_on = [
    module.eks
  ]
}

resource "aws_secretsmanager_secret_version" "shviki_secrets_version" {
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