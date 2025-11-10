#!/bin/bash
set -euo pipefail

echo "🔥 Cleaning Kubernetes LoadBalancers before Terraform destroy..."

# Find and delete all LoadBalancer services safely
LB_SERVICES=$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

if [[ -n "$LB_SERVICES" ]]; then
  echo "$LB_SERVICES" | while read -r ns name; do
    if [[ -n "$ns" && -n "$name" ]]; then
      echo "🧹 Deleting LoadBalancer: $name (namespace: $ns)"
      kubectl delete svc "$name" -n "$ns" --ignore-not-found
    fi
  done
else
  echo "✅ No LoadBalancer services found."
fi

# Use subshell to avoid breaking stdin for next command
{
  echo "🧹 Deleting ingresses..."
  kubectl get ingress --all-namespaces -o name | while read -r ingress; do
    echo "🧼 Deleting ingress: $ingress"
    kubectl delete "$ingress" --ignore-not-found
  done
}

echo "⏳ Waiting 60 seconds for AWS LoadBalancers to fully terminate..."
sleep 60

echo "✅ Kubernetes LoadBalancer cleanup complete!"
