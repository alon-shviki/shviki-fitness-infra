resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.29.1"

  values = [
    yamlencode({
      cloudProvider = "aws"
      awsRegion     = var.region

      autoDiscovery = {
        clusterName = module.eks.cluster_name
      }

      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa.iam_role_arn
          }
        }
      }

      image = {
        tag = "v1.30.0"
      }

      extraArgs = {
        "balance-similar-node-groups" = "true"
        "skip-nodes-with-system-pods" = "false"
        "expander"                    = "least-waste"
        "stderrthreshold"             = "info"
        "v"                           = "4"
      }
    })
  ]

  depends_on = [
    module.eks,
    module.cluster_autoscaler_irsa
  ]
}
