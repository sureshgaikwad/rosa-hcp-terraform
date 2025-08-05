output "cluster_id" {
  description = "ID of the created ROSA cluster"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
}

output "cluster_name" {
  description = "Name of the created ROSA cluster"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.name
}

output "api_url" {
  description = "API URL of the ROSA cluster"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.api_url
}

output "console_url" {
  description = "Console URL of the ROSA cluster"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.console_url
}

output "cluster_admin_username" {
  description = "Username of the cluster admin"
  value       = rhcs_cluster_rosa_hcp_admin_user.cluster_admin.username
}

output "cluster_admin_password" {
  description = "Password of the cluster admin"
  value       = rhcs_cluster_rosa_hcp_admin_user.cluster_admin.password
  sensitive   = true
}

output "cluster_type" {
  description = "Type of cluster deployed (private/public)"
  value       = var.cluster_type
}

output "private_cluster" {
  description = "Whether the cluster is private"
  value       = local.private_cluster
}

output "openshift_version" {
  description = "OpenShift version of the cluster"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.version
}

output "region" {
  description = "AWS region where the cluster is deployed"
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.cloud_region
}

output "oidc_config_id" {
  description = "ID of the OIDC configuration"
  value       = module.oidc_config_and_provider.oidc_config_id
}

output "account_role_prefix" {
  description = "Prefix used for account roles"
  value       = module.create_account_roles.account_role_prefix
}

output "operator_role_prefix" {
  description = "Prefix used for operator roles"
  value       = module.operator_roles.operator_role_prefix
}

output "cluster_id" {
  value = module.rosa_hcp.cluster_id
}
