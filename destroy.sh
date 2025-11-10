#!/bin/bash
set -e

# Step 1: Kubernetes cleanup
echo "🚀 Running pre-destroy cleanup..."
bash ./scripts/k8s-pre-destroy.sh

# Step 2: Terraform destroy
echo "💣 Running Terraform destroy..."
terraform destroy -var-file=tfvars/prod.tfvars -auto-approve
