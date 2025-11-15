# ============================================================
# Summary:
# Configures all required Terraform providers (AWS, Kubernetes, Helm).
# Description:
# This file defines the required versions for Terraform and its
# providers. It also configures the providers to connect to the
# correct AWS region and to authenticate with the EKS cluster
# created by the 'eks.tf' file.
# ============================================================

###############################################################
# Summary: Terraform and Provider Version Requirements
# Description:
# Enforces the minimum version of Terraform and the specific
# versions of the AWS, Kubernetes, and Helm providers. This
# ensures that the infrastructure builds reliably and avoids
# breaking changes from new provider versions.
###############################################################
terraform {
  required_version = ">= 1.6.0" # Requires Terraform version 1.6.0 or newer

  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 4.0.0" }        # Use the official AWS provider
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29" } # Use the official Kubernetes provider
    helm       = { source = "hashicorp/helm", version = "~> 2.12" }       # Use the official Helm provider
  }
}

###############################################################
# Summary: AWS Provider Configuration
# Description:
# Configures the main AWS provider. All AWS resources (like IAM
# roles, VPCs, and the EKS cluster) will be created in the
# specified region using the default AWS credentials profile.
###############################################################
provider "aws" {
  region  = "eu-west-1" # The AWS region for all resources (e.g., Ireland)
  profile = "default"   # The AWS credentials profile from ~/.aws/credentials
}

###############################################################
# Summary: EKS Cluster Authentication Data
# Description:
# This data source dynamically retrieves a short-lived
# authentication token for the specified EKS cluster. This token
# is then passed to the Kubernetes and Helm providers to
# grant them access to the cluster's API.
###############################################################
data "aws_eks_cluster_auth" "this" {
  # The name of the cluster, referenced from the 'eks' module output
  name = module.eks.cluster_name
}

###############################################################
# Summary: Kubernetes Provider Configuration
# Description:
# Configures the 'kubernetes' provider to manage resources
# (like Namespaces and Service Accounts) inside the EKS cluster.
# It authenticates using the cluster's endpoint and the token
# fetched by the 'aws_eks_cluster_auth' data source.
###############################################################
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint                           # The API endpoint URL of the EKS cluster
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data) # The cluster's root certificate
  token                  = data.aws_eks_cluster_auth.this.token                  # The short-lived auth token
}

###############################################################
# Summary: Helm Provider Configuration
# Description:
# Configures the 'helm' provider to manage Helm releases inside
# the EKS cluster. This is used to bootstrap applications like
# Argo CD. It authenticates using the same method as the
# Kubernetes provider.
###############################################################
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint                           # The API endpoint URL of the EKS cluster
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data) # The cluster's root certificate
    token                  = data.aws_eks_cluster_auth.this.token                  # The short-lived auth token
  }
}