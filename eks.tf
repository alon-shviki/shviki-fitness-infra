# ============================================================
# eks.tf
# Summary:
# Creates the Amazon EKS cluster with managed node groups and addons.
# Includes AWS EBS CSI driver (IRSA-enabled) for persistent volumes.
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.8.0"

  # ------------------------------------------------------------
  # Basic configuration
  # ------------------------------------------------------------
  name               = local.eksname
  kubernetes_version = var.eks_version

  # Networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # API access & permissions
  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  # ------------------------------------------------------------
  # EKS Add-ons (Core components + EBS CSI driver)
  # ------------------------------------------------------------
  addons = {
    coredns                = {}
    vpc-cni                = { before_compute = true }
    kube-proxy             = {}
    eks-pod-identity-agent = { before_compute = true }

    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
      most_recent              = true
    }
  }

  # ------------------------------------------------------------
  # Managed Node Groups
  # ------------------------------------------------------------
  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.eks_node_sizes
      desired_size   = 2
      min_size       = 1
      max_size       = 3

      # --- FIX: Converted list to map ---
      iam_role_additional_policies = {
        EBSCSIPolicy = aws_iam_policy.ebs_csi_policy.arn
      }

      labels = {
        role = "system"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"          = "true"
        "k8s.io/cluster-autoscaler/${local.eksname}" = "owned"
      }
    }

    workload = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.eks_node_sizes
      desired_size   = 2
      min_size       = 1
      max_size       = 5

      # --- FIX: Converted list to map ---
      iam_role_additional_policies = {
        EBSCSIPolicy = aws_iam_policy.ebs_csi_policy.arn
      }
      
      labels = {
        role = "workload"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"          = "true"
        "k8s.io/cluster-autoscaler/${local.eksname}" = "owned"
      }
    }
  }

  # ------------------------------------------------------------
  # Tags
  # ------------------------------------------------------------
  tags = local.tags
}