###############################################################
# AWS GP3 StorageClass for EKS (dynamic volume provisioning)
# -----------------------------------------------------------
# This creates a gp3-backed StorageClass in the EKS cluster.
# Purpose:
#   ✔ Make gp3 the StorageClass used for PVCs
#   ✔ Ensure volumes bind only when a pod is scheduled
#   ✔ Allow expanding PVCs later
#
# This replaces manual:
#   kubectl apply -f storageclass.yaml
#
# Trigger:
#   Created automatically after EKS cluster becomes ready
###############################################################

resource "kubernetes_storage_class" "gp3_ebs" {
  metadata {
    name = "gp3-ebs"

    # Mark this as the default StorageClass for the cluster
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  # Amazon EBS CSI driver provisioner
  storage_provisioner = "ebs.csi.aws.com"

  # Delay provisioning until a node is chosen (best practice in EKS)
  volume_binding_mode = "WaitForFirstConsumer"

  # Allow resizing PVCs (e.g., from 1Gi → 5Gi)
  allow_volume_expansion = true

  # EBS volume type
  parameters = {
    type = "gp3"
  }

  # Delete EBS volume when PVC is deleted (default behavior)
  reclaim_policy = "Delete"

  # Must wait until EKS exists
  depends_on = [module.eks]
}
