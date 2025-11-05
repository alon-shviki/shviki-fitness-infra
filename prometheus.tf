resource "helm_release" "prometheus" {
  name       = "kube-prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "61.2.0" # EKS 1.30 compatible

  values = [
    yamlencode({
      grafana = {
        enabled = false   # We install Grafana separately
      }
    })
  ]

  depends_on = [module.eks]
}
