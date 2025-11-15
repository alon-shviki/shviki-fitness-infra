# ============================================================
# variables.tf
# Summary:
# Global input variables controlling AWS region, networking, and EKS settings.
# Description:
# This file defines the main input variables for the Terraform
# infrastructure. These variables allow the environment, region,
# and cluster configuration to be easily changed. Default values
# are set for a standard production-like deployment.
# ============================================================

# The deployment environment (e.g., "prod", "dev", "staging")
variable "environment" {
  type    = string
  default = "prod"
}

# The target AWS region for all infrastructure
variable "region" {
  type    = string
  default = "eu-west-1"
}

# The primary CIDR block for the new VPC
variable "vpc_cidr" {
  type    = string
  default = "10.120.0.0/16"
}

# The number of Availability Zones to span for high availability
variable "num_of_azs" {
  type    = number
  default = 2
}

# The Kubernetes version for the EKS control plane and nodes
variable "eks_version" {
  type    = string
  default = "1.30"
}

# The EC2 instance type(s) to use for the EKS node groups
variable "eks_node_sizes" {
  type    = list(string)
  default = ["t3a.medium"]
}