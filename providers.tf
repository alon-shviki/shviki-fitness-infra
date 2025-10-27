# ============================================================
# providers.tf
# Summary:
# Defines Terraform version, required providers (AWS, Kubernetes, Helm)
# and configures them to connect dynamically to the EKS cluster outputs.
# ============================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Allow v6 (and future 6.x) to satisfy modules that require >=6.15
      version = ">= 6.15.0, < 7.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# --- AWS provider (reads region from var.region) ---
provider "aws" {
  region = var.region
}

# --- EKS auth token for Kubernetes/Helm providers ---
# (uses EKS outputs provided by module "eks" after creation)
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# --- Kubernetes provider (talks to the EKS API server) ---
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# --- Helm provider (reuses same k8s connection) ---
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
