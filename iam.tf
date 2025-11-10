# ============================================================
# EBS CSI DRIVER IRSA (Your existing, working code)
# ============================================================

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${local.environment}-ebs-csi-policy"
  description = "EKS EBS CSI driver permissions"
  policy      = jsonencode({
    Version   = "2012-10-17",
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
# CLUSTER AUTOSCALER IRSA (Your existing, working code)
# ============================================================

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-cluster-autoscaler-policy"
  description = "EKS Cluster Autoscaler permissions"
  policy = jsonencode({
    Version   = "2012-10-17",
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
# SECRETS POLICY (This is the *one* policy both roles will share)
# ============================================================

resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${local.environment}-external-secrets-policy"
  description = "Allows reading app secrets from Secrets Manager and decrypting with KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        # Grants access ONLY to the secret we created
        Resource = aws_secretsmanager_secret.shviki_secrets.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        # Grants access ONLY to your EKS key
        Resource = module.eks.kms_key_arn
      }
    ]
  })
}

# ============================================================
# IRSA FOR EXTERNAL SECRETS OPERATOR (Fix 1 of 2)
# ============================================================

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
  depends_on = [
    module.eks
  ]
}

module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"
  create_role  = true
  role_name    = "${local.environment}-external-secrets-role" # Role for the operator
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [
    aws_iam_policy.external_secrets_policy.arn # Attaches the shared policy
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:external-secrets:external-secrets-sa" # Links to operator's SA
  ]
}

resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.iam_role_arn # Annotates with its role
    }
  }
  depends_on = [
    module.eks,
    module.external_secrets_irsa
  ]
}

# ============================================================
# IRSA FOR SHVIKI-FITNESS APP (Fix 2 of 2)
# ============================================================

module "shviki_fitness_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"
  create_role  = true
  role_name    = "${local.environment}-shviki-fitness-app-role" # Role for the app
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [
    aws_iam_policy.external_secrets_policy.arn # Attaches the *same* shared policy
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:sh:shviki-fitness-sa" # Links to your app's SA
  ]
}

resource "kubernetes_service_account" "shviki_fitness_sa" {
  metadata {
    name      = "shviki-fitness-sa"
    namespace = "sh" # Your app's namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.shviki_fitness_irsa.iam_role_arn # Annotates with its *own* role
    }
  }
  depends_on = [
    module.eks,
    module.shviki_fitness_irsa
  ]
}