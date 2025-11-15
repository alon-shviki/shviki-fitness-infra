# ============================================================
# Summary:
# Defines and deploys the Amazon EKS cluster including networking,
# managed node groups, and core Kubernetes addons.
# Description:
# This configuration provisions the EKS control plane, system and
# workload node groups, and integrates required components such as
# the EBS CSI driver via IRSA. Node groups are labeled and tainted
# for clear workload separation.
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 21.8.0"

  # ------------------------------------------------------------
  # Basic configuration
  # ------------------------------------------------------------
  name               = local.eksname
  kubernetes_version = var.eks_version

  # Networking configuration
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # API access settings
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

      # Additional IAM permissions for EBS CSI driver
      iam_role_additional_policies = {
        EBSCSIPolicy = aws_iam_policy.ebs_csi_policy.arn
      }

      # Scheduling constraints
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

      # Required for Cluster Autoscaler
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

      # Additional IAM permissions for EBS CSI driver
      iam_role_additional_policies = {
        EBSCSIPolicy = aws_iam_policy.ebs_csi_policy.arn
      }

      # Scheduling labels
      labels = {
        role = "workload"
      }

      # Required for Cluster Autoscaler
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
