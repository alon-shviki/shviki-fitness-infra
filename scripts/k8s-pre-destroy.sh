# Summary: Cleanup Script for Kubernetes LoadBalancers Before Terraform Destroy
# Description:
# Safely deletes all Kubernetes LoadBalancer Services and Ingress resources.
# Helps ensure AWS Load Balancers are terminated before running terraform destroy.

#!/bin/bash
set -euo pipefail

echo "Cleaning Kubernetes LoadBalancers before Terraform destroy..."

# Identify all LoadBalancer Services across namespaces
LB_SERVICES=$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

# Delete each LoadBalancer Service if present
if [[ -n "$LB_SERVICES" ]]; then
  echo "$LB_SERVICES" | while read -r ns name; do
    if [[ -n "$ns" && -n "$name" ]]; then
      echo "Deleting LoadBalancer: $name (namespace: $ns)"
      kubectl delete svc "$name" -n "$ns" --ignore-not-found
    fi
  done
else
  echo "No LoadBalancer services found."
fi

# Delete all Ingress resources
{
  echo "Deleting ingresses..."
  kubectl get ingress --all-namespaces -o name | while read -r ingress; do
    echo "Deleting ingress: $ingress"
    kubectl delete "$ingress" --ignore-not-found
  done
}

# Allow time for AWS to fully remove related load balancers
echo "Waiting 60 seconds for AWS LoadBalancers to terminate..."
sleep 30

echo "Kubernetes LoadBalancer cleanup complete."
