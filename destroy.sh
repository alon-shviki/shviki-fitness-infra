# Summary: Full Cleanup and Terraform Destroy Script
# Description:
# Executes a Kubernetes cleanup script to remove LoadBalancer resources
# before running a full Terraform destroy on the production environment.

#!/bin/bash
set -e

# Run Kubernetes cleanup to remove LoadBalancers and ingress resources
echo "Running pre-destroy cleanup..."
bash ./scripts/k8s-pre-destroy.sh

# Execute Terraform destroy using the production tfvars file
echo "Running Terraform destroy..."
terraform destroy -var-file=tfvars/prod.tfvars -auto-approve
