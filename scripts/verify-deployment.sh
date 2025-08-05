# Create verification script
cat > scripts/verify-deployment.sh << 'EOF'
#!/bin/bash

echo "=== ROSA Cluster Verification ==="
echo "Cluster Name: $(terraform output -raw cluster_name)"
echo "API URL: $(terraform output -raw api_url)"
echo "Console URL: $(terraform output -raw console_url)"
echo ""

echo "=== Node Status ==="
oc get nodes

echo ""
echo "=== OpenShift AI Verification ==="
echo "DataScienceCluster Status:"
oc get datasciencecluster default-dsc -o jsonpath='{.status.phase}' 2>/dev/null || echo "Not ready yet"
echo ""
echo "OpenShift AI Components:"
oc get pods -n redhat-ods-applications 2>/dev/null | head -5

echo ""
echo "=== OpenShift GitOps Verification ==="
echo "ArgoCD Status:"
oc get argocd openshift-gitops -n openshift-gitops -o jsonpath='{.status.phase}' 2>/dev/null || echo "Not ready yet"
echo ""
echo "ArgoCD Applications:"
oc get applications -n openshift-gitops

echo ""
echo "=== Vote Application Verification ==="
echo "Vote App Status:"
oc get application vote-app-dev -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Not deployed"
echo ""
echo "Vote App Resources:"
oc get all -n vote-app-dev 2>/dev/null | head -10

echo ""
echo "=== Service URLs ==="
echo "OpenShift Console: $(terraform output -raw console_url)"
echo "ArgoCD Dashboard: $(terraform output -raw argocd_url)"
echo "OpenShift AI Dashboard: $(terraform output -raw openshift_ai_dashboard)"

echo ""
echo "=== Access Information ==="
echo "Cluster Admin Username: $(terraform output -raw cluster_admin_username)"
echo "Cluster Admin Password: [HIDDEN - use terraform output -raw cluster_admin_password]"
echo "ArgoCD Admin Password Command: $(terraform output -raw argocd_admin_password_command)"
EOF

chmod +x scripts/verify-deployment.sh
