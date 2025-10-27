# ============================================================
# iam.tf
# Summary:
# Creates IAM roles and policies for EKS add-ons (Cluster Autoscaler).
# Demonstrates IRSA pattern via OIDC provider trust.
# ============================================================
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.46.0"

  create_role  = true
  role_name    = "${local.environment}-cluster-autoscaler"
  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.environment}-cluster-autoscaler-policy"
  description = "EKS Cluster Autoscaler permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "autoscaling:Describe*",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      Resource = "*"
    }]
  })
}
