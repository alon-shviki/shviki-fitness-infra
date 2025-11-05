resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.5.0"

  values = [
    yamlencode({
      adminPassword = "ShvikiStrongPassword123" # change this
      service = {
        type = "LoadBalancer"
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}
