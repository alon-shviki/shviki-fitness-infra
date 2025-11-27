# Summary: ArgoCD Installation via Terraform
# Description:
# Creates the ArgoCD namespace and installs the ArgoCD Helm chart on the EKS cluster.
# Namespace is provisioned first, then Helm deploys ArgoCD using the provided values.yaml.

# ------------------------------------------------------------
# ArgoCD Namespace Definition
# ------------------------------------------------------------
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  # Ensure EKS cluster exists before creating namespace
  depends_on = [module.eks]
}

# ------------------------------------------------------------
# ArgoCD Helm Release Installation
# ------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name

  # ArgoCD Helm chart source
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.2"

  create_namespace = false

  # External values file
  values = [file("${path.module}/argocd/values.yaml")]

  # Deployment reliability settings
  timeout = 900
  wait    = true

  set {
    name  = "repoServer.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.shviki_fitness_irsa.iam_role_arn 
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd
  ]
}
