#!/bin/bash

echo "=== ROSA Cluster Status ==="
echo "Cluster Name: $(terraform output -raw cluster_name)"
echo "Cluster Type: $(terraform output -raw cluster_type)"
echo "API URL: $(terraform output -raw api_url)"
echo "Console URL: $(terraform output -raw console_url)"
echo ""

echo "=== Node Status ==="
oc get nodes -o wide

echo ""
echo "=== Cluster Operators Status ==="
oc get co | grep -E "(AVAILABLE|PROGRESSING|DEGRADED)" | head -1
oc get co | grep -v "True.*False.*False" | tail -n +2

echo ""
echo "=== OpenShift AI Status ==="
echo "DataScienceCluster:"
oc get datasciencecluster default-dsc -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,READY:.status.conditions[0].status 2>/dev/null || echo "Not ready"
echo ""
echo "AI Workbench Pods:"
oc get pods -n redhat-ods-applications -l component=workbench 2>/dev/null | head -5

echo ""
echo "=== OpenShift GitOps Status ==="
echo "ArgoCD Server:"
oc get pods -n openshift-gitops -l app.kubernetes.io/name=openshift-gitops-server 2>/dev/null
echo ""
echo "Applications:"
oc get applications -n openshift-gitops -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status 2>/dev/null

echo ""
echo "=== Vote Application Status ==="
if oc get application vote-app-dev -n openshift-gitops >/dev/null 2>&1; then
    echo "Application Status:"
    oc get application vote-app-dev -n openshift-gitops -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
    echo ""
    echo "Application Resources:"
    oc get all -n vote-app-dev 2>/dev/null
else
    echo "Vote application not deployed or not ready yet"
fi

echo ""
echo "=== Resource Usage ==="
oc adm top nodes 2>/dev/null || echo "Metrics not available yet"

echo ""
echo "=== Recent Events ==="
oc get events --sort-by='.lastTimestamp' -A | tail -10
