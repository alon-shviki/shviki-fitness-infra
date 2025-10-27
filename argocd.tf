# ============================================================
# argocd.tf
# Summary:
# Installs Argo CD in the EKS cluster using the Helm provider.
# ============================================================
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.31.0"

  create_namespace = true

  values = [yamlencode({
    server = { extraArgs = ["--insecure"] }
  })]

  depends_on = [module.eks]
}
