# ============================================================
# EBS CSI DRIVER IRSA
# Purpose: Allows Kubernetes to manage EBS volumes securely via IAM (IRSA)
# ============================================================

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${local.environment}-ebs-csi-policy"
  description = "EKS EBS CSI driver permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:ModifyVolume"
        ]
        Resource = "*"
      }
    ]
  })
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role  = true
  role_name    = "${local.environment}-ebs-csi-driver"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns              = [aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# ============================================================
# CLUSTER AUTOSCALER IRSA
# Purpose: Allows Kubernetes to scale EKS nodes automatically (via AWS ASG APIs)
# ============================================================

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-cluster-autoscaler-policy"
  description = "EKS Cluster Autoscaler permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeImages"
        ]
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

  role_policy_arns = [
    aws_iam_policy.cluster_autoscaler.arn
  ]

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:cluster-autoscaler"
  ]
}

# ============================================================
# Purpose: Creates the SA for ArgoCD-deployed Cluster Autoscaler Helm chart
# NOTE: If ArgoCD will create the ServiceAccount itself, you can remove this block.
# ============================================================

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa.iam_role_arn
    }
  }

  depends_on = [
    module.cluster_autoscaler_irsa,
    module.eks
  ]
}

# ============================================================
# EXTERNAL SECRETS OPERATOR (ESO)
# ============================================================

#This is the namespace where the operator will live
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }

  depends_on = [
    module.eks
  ]
}

#This policy allows ESO to READ your new secret
#    and DECRYPT it using your EKS KMS key
resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${local.environment}-external-secrets-policy"
  description = "Allows ESO to read app secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        # IMPORTANT: This grants access ONLY to the secret we created
        Resource = aws_secretsmanager_secret.shviki_secrets.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        # This is the correct reference to your EKS module's KMS key
        Resource = module.eks.kms_key_arn
      }
    ]
  })
}

#This is the IRSA role, just like your cluster-autoscaler one
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role  = true
  role_name    = "${local.environment}-external-secrets-role"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.external_secrets_policy.arn
  ]

  # This links the role to the SA we are about to create
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:external-secrets:external-secrets-sa"
  ]
}

# This creates the Service Account (SA) inside Kubernetes
#    and annotates it with the IAM role
resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      # This is the magic link to the IAM role
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.iam_role_arn
    }
  }

  depends_on = [
    module.eks,
    module.external_secrets_irsa
  ]
}