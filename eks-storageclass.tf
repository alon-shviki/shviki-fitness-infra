###############################################################
# Summary: GP3 StorageClass Definition for EKS
# Description:
# Creates a gp3-backed Kubernetes StorageClass for dynamic volume
# provisioning in EKS. Marks gp3 as the cluster default, enables
# volume expansion, and delays binding until pod scheduling.
###############################################################

resource "kubernetes_storage_class" "gp3_ebs" {
  metadata {
    name = "gp3-ebs"

    # Default StorageClass for the cluster
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  # EBS CSI driver provisioner
  storage_provisioner = "ebs.csi.aws.com"

  # Wait until a pod is scheduled before binding storage
  volume_binding_mode = "WaitForFirstConsumer"

  # Allow PVC size expansions
  allow_volume_expansion = true

  # EBS gp3 volume type
  parameters = {
    type = "gp3"
  }

  # Delete EBS volume when PVC is deleted
  reclaim_policy = "Delete"

  depends_on = [module.eks]
}
