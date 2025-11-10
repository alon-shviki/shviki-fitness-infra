# ============================================================
# ArgoCD Namespace
# ============================================================
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [module.eks]
}

# ============================================================
# ArgoCD Helm Release
# ============================================================
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.2"
  create_namespace = false

  values = [file("${path.module}/argocd/values.yaml")]

  timeout = 900
  wait    = true

  depends_on = [module.eks, kubernetes_namespace.argocd]
}
