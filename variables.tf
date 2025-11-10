# ============================================================
# variables.tf
# Summary:
# Global input variables controlling AWS region, networking, and EKS settings.
# ============================================================

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.120.0.0/16"
}

variable "num_of_azs" {
  type    = number
  default = 2
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "eks_node_sizes" {
  type    = list(string)
  default = ["t3a.medium"]
}

