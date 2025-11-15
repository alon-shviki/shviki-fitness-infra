# ============================================================
# vpc.tf
# Summary:
# Provisions AWS VPC, subnets, NAT gateway, and Kubernetes tags.
# Description:
# This file uses the official 'terraform-aws-modules/vpc' module
# to create a new Virtual Private Cloud (VPC) with public, private,
# and intra subnets. It also provisions a NAT Gateway to allow
# private subnets to access the internet.
# ============================================================

###############################################################
# Summary: AWS Availability Zones Data Source
# Description:
# This data source retrieves a list of all available Availability
# Zones (AZs) in the configured AWS region. This allows the VPC
# to be dynamically provisioned across the number of AZs
# specified in 'var.num_of_azs'.
###############################################################
data "aws_availability_zones" "available" {}

###############################################################
# Summary: AWS VPC Module
# Description:
# This module provisions the entire networking stack for the
# EKS cluster, including the VPC, subnets across multiple AZs,
# route tables, and a NAT Gateway.
###############################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  # Naming and IP Range
  name = "${local.name_prefix}-vpc" # The name for the VPC (e.g., "shviki-fitness-prod-vpc")
  cidr = var.vpc_cidr               # The primary IP block for the VPC (e.g., "10.120.0.0/16")
  azs  = slice(data.aws_availability_zones.available.names, 0, var.num_of_azs) # Slices the list of AZs to the number we want (e.g., 2)

  # Subnet Configuration
  public_subnets  = ["10.120.1.0/24", "10.120.2.0/24"]    # Subnets for public-facing resources (like Load Balancers)
  private_subnets = ["10.120.11.0/24", "10.120.12.0/24"] # Subnets for EKS nodes and internal resources
  intra_subnets   = ["10.120.21.0/24", "10.120.22.0/24"] # Additional private subnets, often for databases

  # NAT Gateway Configuration
  enable_nat_gateway = true # Provisions a NAT Gateway to allow private subnets outbound internet
  single_nat_gateway = true # Creates one NAT Gateway and shares it (saves cost)

  # Kubernetes Tagging
  # These tags are required by Kubernetes to discover subnets for Load Balancers
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }            # Tags public subnets for external-facing ELBs
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }   # Tags private subnets for internal ELBs

  # Global Tags
  tags = local.tags # Applies global project tags (like "Environment=prod")
}