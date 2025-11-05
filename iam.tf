# ============================================================
# EBS CSI Driver IRSA
# Summary:
# Creates IAM role for the Amazon EBS CSI Driver to manage EBS volumes.
# ============================================================

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role  = true
  role_name    = "${local.environment}-ebs-csi-driver"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns              = [aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${local.environment}-ebs-csi-policy"
  description = "EKS EBS CSI driver permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ],
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# Cluster Autoscaler IRSA
# Summary:
# Creates IAM role for Kubernetes Cluster Autoscaler.
# Allows EKS to scale worker nodes automatically based on demand.
# ============================================================

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-cluster-autoscaler-policy"
  description = "EKS Cluster Autoscaler permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:Describe*",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeImages"
        ],
        Resource = "*"
      }
    ]
  })
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role  = true
  role_name    = "${local.environment}-cluster-autoscaler"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [aws_iam_policy.cluster_autoscaler.arn]

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:cluster-autoscaler"
  ]
}
