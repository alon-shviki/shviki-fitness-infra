# #############################################
# # ShvikiFitness - Import AWS Secrets & Push to Kubernetes
# # This file DOES NOT create secrets — they already exist in AWS
# # This file ONLY reads AWS secrets and syncs them into Kubernetes namespace "sh"
# #############################################

# ########### READ EXISTING SECRETS FROM AWS ################

# # Read MySQL root secret metadata (path: /shviki/mysql/root)
# data "aws_secretsmanager_secret" "mysql_root" {
#   name = "/shviki/mysql/root"
# }

# # Read MySQL root secret value (actual password JSON)
# data "aws_secretsmanager_secret_version" "mysql_root_v" {
#   secret_id = data.aws_secretsmanager_secret.mysql_root.id
# }

# # Read MySQL app credentials (user/password/db)
# data "aws_secretsmanager_secret" "mysql_app" {
#   name = "/shviki/mysql/app"
# }

# data "aws_secretsmanager_secret_version" "mysql_app_v" {
#   secret_id = data.aws_secretsmanager_secret.mysql_app.id
# }

# # Read Flask SECRET_KEY secret
# data "aws_secretsmanager_secret" "flask" {
#   name = "/shviki/flask/secret"
# }

# data "aws_secretsmanager_secret_version" "flask_v" {
#   secret_id = data.aws_secretsmanager_secret.flask.id
# }

# # Read RapidAPI exercise API key + host
# data "aws_secretsmanager_secret" "rapidapi" {
#   name = "/shviki/rapidapi"
# }

# data "aws_secretsmanager_secret_version" "rapidapi_v" {
#   secret_id = data.aws_secretsmanager_secret.rapidapi.id
# }

# # Read GitHub token for ArgoCD automation
# data "aws_secretsmanager_secret" "argo_github" {
#   name = "/shviki/github/argo"
# }

# data "aws_secretsmanager_secret_version" "argo_github_v" {
#   secret_id = data.aws_secretsmanager_secret.argo_github.id
# }

# ########### DECODE AWS JSON SECRET STRINGS ################
# # Convert AWS secret JSON into Terraform maps

# locals {
#   mysql_root       = jsondecode(data.aws_secretsmanager_secret_version.mysql_root_v.secret_string)
#   mysql_app        = jsondecode(data.aws_secretsmanager_secret_version.mysql_app_v.secret_string)
#   flask_secret     = jsondecode(data.aws_secretsmanager_secret_version.flask_v.secret_string)
#   rapidapi_secrets = jsondecode(data.aws_secretsmanager_secret_version.rapidapi_v.secret_string)
#   argo_github      = jsondecode(data.aws_secretsmanager_secret_version.argo_github_v.secret_string)
# }

# ########### CREATE KUBERNETES SECRET ################
# # Convert AWS Secrets → Kubernetes Secret `shviki-secrets`
# # Stored in namespace "sh" (where your app + MySQL live)

# resource "kubernetes_secret" "shviki_app" {
#   metadata {
#     name      = "shviki-secrets"
#     namespace = "sh"   # ✅ namespace where your app runs
#   }

#   # Map AWS secret values to K8s secret keys
#   data = {
#     mysql_root_password = local.mysql_root.MYSQL_ROOT_PASSWORD
#     mysql_user          = local.mysql_app.MYSQL_USER
#     mysql_user_password = local.mysql_app.MYSQL_PASSWORD
#     mysql_database      = local.mysql_app.MYSQL_DATABASE
#     flask_secret_key    = local.flask_secret.SECRET_KEY
#     rapidapi_key        = local.rapidapi_secrets.EXERCISE_API_KEY
#     rapidapi_host       = local.rapidapi_secrets.EXERCISE_API_HOST
#     github_token        = local.argo_github.GITHUB_TOKEN
#   }

#   # Kubernetes secret type
#   type = "Opaque"
# }
