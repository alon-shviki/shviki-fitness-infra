# ============================================================
# eks.tf
# Summary:
# Creates the Amazon EKS cluster with managed node group and addons.
# ============================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name_prefix}-eks"
  kubernetes_version = var.eks_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  addons = {
    coredns                = {}
    vpc-cni                = { before_compute = true }
    kube-proxy             = {}
    eks-pod-identity-agent = { before_compute = true }
  }

  eks_managed_node_groups = {
    nodes1 = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.eks_node_sizes
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      capacity_type  = "SPOT"
    }
  }

  tags = local.tags
}
