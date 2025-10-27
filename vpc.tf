# ============================================================
# vpc.tf
# Summary:
# Provisions AWS VPC, subnets, NAT gateway, and Kubernetes tags.
# ============================================================
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, var.num_of_azs)

  public_subnets  = ["10.120.1.0/24", "10.120.2.0/24"]
  private_subnets = ["10.120.11.0/24", "10.120.12.0/24"]
  intra_subnets   = ["10.120.21.0/24", "10.120.22.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }

  tags = local.tags
}
