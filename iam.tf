# ============================================================
# EBS CSI DRIVER IRSA
# Summary:
# Provides IAM permissions and OIDC role binding for the AWS EBS CSI driver.
# Description:
# This policy grants the necessary EC2 permissions (create, attach, delete
# volumes) for the EBS CSI driver. The module then creates an IAM role
# that trusts the EKS OIDC provider, allowing the Kubernetes service
# account 'ebs-csi-controller-sa' to assume this role (IRSA).
# ============================================================

###############################################################
# Summary: IAM Policy for AWS EBS CSI Driver
# Description:
# Defines the specific AWS permissions required by the EBS CSI
# driver to manage EC2 volumes on behalf of Kubernetes.
###############################################################
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${local.environment}-ebs-csi-policy"
  description = "EKS EBS CSI driver permissions"

  # The JSON policy document granting EC2 volume permissions
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
        Resource = "*" # Applies permissions to all resources (required by EBS CSI)
      }
    ]
  })
}

###############################################################
# Summary: IRSA Role for EBS CSI Driver
# Description:
# Creates the IAM Role that will be assumed by the EBS CSI
# driver's Kubernetes Service Account in the 'kube-system' namespace.
###############################################################
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role                     = true                                     # Instructs the module to create a new IAM role
  role_name                       = "${local.environment}-ebs-csi-driver"    # The unique name for the IAM role
  provider_url                    = replace(module.eks.cluster_oidc_issuer_url, "https://", "") # The EKS cluster's OIDC provider URL (for trust relationship)
  role_policy_arns                = [aws_iam_policy.ebs_csi_policy.arn]      # Attaches the 'ebs_csi_policy' created above
  oidc_fully_qualified_subjects   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"] # The K8s Service Account that can assume this role
}

# ============================================================
# CLUSTER AUTOSCALER IRSA
# Summary:
# Grants the Cluster Autoscaler required IAM permissions and binds them
# via IRSA to its Kubernetes service account.
# Description:
# This policy allows the autoscaler to describe and modify Auto Scaling
# Groups. The module creates the IAM role, and the 'kubernetes_service_account'
# resource creates the corresponding SA in 'kube-system' annotated
# with the role's ARN.
# ============================================================

###############################################################
# Summary: IAM Policy for Cluster Autoscaler
# Description:
# Defines permissions for managing Auto Scaling Groups and EC2
# instances, required for scaling nodes up and down.
###############################################################
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-cluster-autoscaler-policy"
  description = "EKS Cluster Autoscaler permissions"

  # The JSON policy document
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
        Resource = "*" # Applies permissions to all resources (required by Cluster Autoscaler)
      }
    ]
  })
}

###############################################################
# Summary: IRSA Role for Cluster Autoscaler
# Description:
# Creates the IAM Role that will be assumed by the Cluster
# Autoscaler's Kubernetes Service Account.
###############################################################
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role                   = true                                     # Instructs the module to create a new IAM role
  role_name                     = "${local.environment}-cluster-autoscaler"  # The unique name for the IAM role
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "") # The EKS cluster's OIDC provider URL
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]  # Attaches the 'cluster_autoscaler' policy created above
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"] # The K8s Service Account that can assume this role
}

###############################################################
# Summary: Kubernetes Service Account for Cluster Autoscaler
# Description:
# Creates the 'cluster-autoscaler' Service Account within the
# 'kube-system' namespace and annotates it with the IAM role ARN.
# This completes the IRSA link.
###############################################################
resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler" # Name of the Service Account (must match Argo CD chart)
    namespace = "kube-system"        # Namespace where the autoscaler pod runs
    annotations = {
      # This annotation is the "magic" that links the K8s SA to the AWS IAM role
      "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa.iam_role_arn
    }
  }

  # Ensures this SA is not created until the EKS cluster and IAM role exist
  depends_on = [
    module.cluster_autoscaler_irsa,
    module.eks
  ]
}

# ============================================================
# SECRETS POLICY
# Summary:
# IAM policy granting access to Secrets Manager + KMS decryption.
# Description:
# This single, secure policy defines the *minimum* permissions
# needed to read the app's secret from AWS Secrets Manager and
# decrypt it using the EKS cluster's specific KMS key.
# It is shared by both the Operator and the App roles.
# ============================================================

###############################################################
# Summary: IAM Policy for AWS Secrets Manager & KMS
# Description:
# Defines read-only permissions for a specific Secrets Manager
# secret and decryption permissions for a specific KMS key.
###############################################################
resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${local.environment}-external-secrets-policy"
  description = "Allows reading app secrets from Secrets Manager and decrypting with KMS"

  # The JSON policy document
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Statement 1: Allow reading the specific secret
      {
        Effect  = "Allow",
        Action  = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        # Limits permissions to *only* the secret created in secrets.tf
        Resource = aws_secretsmanager_secret.shviki_secrets.arn
      },
      # Statement 2: Allow decrypting with the specific KMS key
      {
        Effect  = "Allow",
        Action  = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        # Limits permissions to *only* the EKS cluster's KMS key
        Resource = module.eks.kms_key_arn
      }
    ]
  })
}

# ============================================================
# IRSA FOR EXTERNAL SECRETS OPERATOR
# Summary:
# Creates namespace, service account, and IAM role for the External Secrets Operator.
# Description:
# The operator uses this role and service account to securely
# communicate with AWS and fetch secrets on behalf of other apps.
# ============================================================

###############################################################
# Summary: Kubernetes Namespace for External Secrets
# Description:
# Creates a dedicated 'external-secrets' namespace to isolate
# the operator's components.
###############################################################
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets" # Name of the new namespace
  }
  depends_on = [module.eks] # Ensures EKS is ready before creating
}

###############################################################
# Summary: IRSA Role for External Secrets Operator
# Description:
# Creates the IAM Role that will be assumed by the External
# Secrets Operator's Service Account.
###############################################################
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role       = true                                     # Instructs the module to create a new IAM role
  role_name         = "${local.environment}-external-secrets-role" # The unique name for the IAM role
  provider_url      = replace(module.eks.cluster_oidc_issuer_url, "https://", "") # The EKS cluster's OIDC provider URL
  role_policy_arns  = [aws_iam_policy.external_secrets_policy.arn] # Attaches the *shared* secrets policy
  oidc_fully_qualified_subjects = [
    # The K8s Service Account (in the 'external-secrets' namespace) that can assume this role
    "system:serviceaccount:external-secrets:external-secrets-sa"
  ]
}

###############################################################
# Summary: Kubernetes Service Account for External Secrets Operator
# Description:
# Creates the 'external-secrets-sa' Service Account within the
# 'external-secrets' namespace and annotates it with its IAM role ARN.
###############################################################
resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa" # Name of the Service Account (must match Argo CD chart)
    namespace = kubernetes_namespace.external_secrets.metadata[0].name # Deploys into the new namespace
    annotations = {
      # Links this K8s SA to the AWS IAM role
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.iam_role_arn
    }
  }
  depends_on = [
    module.eks,
    module.external_secrets_irsa
  ]
}

# ============================================================
# IRSA FOR SHVIKI-FITNESS APP
# Summary:
# Creates IAM role + Kubernetes service account for the Flask app.
# Description:
# Allows the main 'shviki-fitness' application (running in the
# 'sh' namespace) to assume its *own* IAM role. This lets the
# 'SecretStore' resource verify the app's identity and use its
# permissions to fetch secrets.
# ============================================================

###############################################################
# Summary: IRSA Role for ShvikiFitness Application
# Description:
# Creates the IAM Role that will be assumed by the main Flask
# application's Service Account.
###############################################################
module "shviki_fitness_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role      = true                                     # Instructs the module to create a new IAM role
  role_name        = "${local.environment}-shviki-fitness-app-role" # The unique name for the app's IAM role
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "") # The EKS cluster's OIDC provider URL
  role_policy_arns = [aws_iam_policy.external_secrets_policy.arn] # Attaches the *same* shared secrets policy
  oidc_fully_qualified_subjects = [
    # The K8s Service Account (in the 'sh' namespace) that can assume this role
    "system:serviceaccount:sh:shviki-fitness-sa-v2"
  ]
}

# ============================================================
# resource: kubernetes_config_map.shviki_irsa_config
# Summary:
# Exposes the IRSA IAM Role ARN for the ShvikiFitness app to
# the cluster via a ConfigMap in the 'argocd' namespace.
# Helm (in the app repo) will read this value dynamically,
# so the AWS account ID never appears in Git.
# ============================================================

resource "kubernetes_config_map" "shviki_irsa_config" {
  metadata {
    name      = "shviki-irsa-config"
    namespace = "argocd"

    labels = {
      app       = "shviki-fitness"
      component = "irsa-config"
    }
  }

  data = {
    # IAM role ARN created by the shviki_fitness_irsa module
    iam_role_arn = module.shviki_fitness_irsa.iam_role_arn
  }

  depends_on = [
    module.eks,
    module.shviki_fitness_irsa
  ]
}

resource "kubernetes_service_account" "shviki_fitness" {
  metadata {
    name      = "shviki-fitness-sa-v2"
    namespace = "sh"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.shviki_fitness_irsa.iam_role_arn
    }
  }

  depends_on = [
    module.shviki_fitness_irsa,
    module.eks,
    kubernetes_namespace.sh
  ]
}

resource "kubernetes_namespace" "sh" {
  metadata {
    name = "sh"
  }

  depends_on = [module.eks]
}
  

