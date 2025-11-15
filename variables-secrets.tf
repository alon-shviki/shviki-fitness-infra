###############################################################
# Summary: Secret Variable Declarations
# Description:
# This file declares all sensitive variables used by the Terraform
# configuration. The actual values for these variables are
# provided in the 'secrets.auto.tfvars' file, which is git-ignored.
#
# Setting 'sensitive = true' prevents Terraform from printing these
# values in plans or logs, enhancing security.
###############################################################

variable "mysql_root_password" {
  type      = string
  sensitive = true
  description = "Root password for MySQL"
}

variable "mysql_user" {
  type      = string
  sensitive = true
  description = "Application username for MySQL"
}

variable "mysql_user_password" {
  type      = string
  sensitive = true
  description = "Password for the application user"
}

variable "mysql_database" {
  type      = string
  sensitive = true
  description = "Name of the MySQL database"
}

variable "flask_secret_key" {
  type      = string
  sensitive = true
  description = "Flask app secret key"
}

variable "rapidapi_key" {
  type      = string
  sensitive = true
  description = "RapidAPI key for gym/food APIs"
}