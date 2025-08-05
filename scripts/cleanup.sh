#!/bin/bash

echo "WARNING: This will destroy your ROSA cluster and all data!"
echo "This includes:"
echo "- ROSA HCP cluster"
echo "- All applications deployed via ArgoCD"
echo "- OpenShift AI workbenches and models"
echo "- All persistent volumes and data"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Starting cleanup process..."
    
    # Create final backup
    echo "Creating final backup..."
    ./scripts/backup-config.sh
    
    # Remove ArgoCD applications first to avoid hanging resources
    echo "Removing ArgoCD applications..."
    oc delete application vote-app-dev -n openshift-gitops --wait=false 2>/dev/null || true
    
    # Wait for applications to be removed
    sleep 30
    
    # Destroy Terraform resources
    echo "Destroying Terraform resources..."
    terraform destroy -auto-approve
    
    echo "Cleanup completed"
    echo "Backup created in backups/ directory"
else
    echo "Cleanup cancelled"
fi
