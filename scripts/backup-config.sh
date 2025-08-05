#!/bin/bash

BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Creating backup in $BACKUP_DIR"

# Backup Terraform state and configuration
cp terraform.tfstate* $BACKUP_DIR/ 2>/dev/null || true
cp *.tf $BACKUP_DIR/
cp environments/*/*.tfvars $BACKUP_DIR/ 2>/dev/null || true

# Backup cluster configuration
echo "Backing up cluster resources..."
oc get all -A -o yaml > $BACKUP_DIR/all-resources.yaml
oc get configmaps -A -o yaml > $BACKUP_DIR/configmaps.yaml
oc get secrets -A -o yaml > $BACKUP_DIR/secrets.yaml
oc get pv,pvc -A -o yaml > $BACKUP_DIR/storage.yaml

# Backup OpenShift AI configuration
echo "Backing up OpenShift AI configuration..."
oc get datasciencecluster -o yaml > $BACKUP_DIR/datasciencecluster.yaml 2>/dev/null || true
oc get notebooks -A -o yaml > $BACKUP_DIR/notebooks.yaml 2>/dev/null || true

# Backup ArgoCD configuration
echo "Backing up ArgoCD configuration..."
oc get applications -A -o yaml > $BACKUP_DIR/argocd-applications.yaml 2>/dev/null || true
oc get appprojects -A -o yaml > $BACKUP_DIR/argocd-projects.yaml 2>/dev/null || true
oc get argocd -A -o yaml > $BACKUP_DIR/argocd-instances.yaml 2>/dev/null || true

# Create backup summary
cat > $BACKUP_DIR/backup-summary.txt << SUMMARY
Backup created: $(date)
Cluster: $(terraform output -raw cluster_name 2>/dev/null || echo "Unknown")
API URL: $(terraform output -raw api_url 2>/dev/null || echo "Unknown")
Terraform Version: $(terraform version | head -1)
ROSA Version: $(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}' 2>/dev/null || echo "Unknown")

Files included:
- Terraform state and configuration
- All cluster resources
- OpenShift AI configuration
- ArgoCD applications and projects
- ConfigMaps and Secrets
- Storage resources
SUMMARY

echo "Backup completed: $BACKUP_DIR"
echo "Summary:"
cat $BACKUP_DIR/backup-summary.txt
