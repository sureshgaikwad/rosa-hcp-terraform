terraform {
  required_version = ">= 1.0"
  required_providers {
    rhcs = {
      version = ">= 1.6.2"
      source  = "terraform-redhat/rhcs"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

# Configure the RHCS Provider
provider "rhcs" {
  # token and url are set via environment variables:
  # RHCS_TOKEN and RHCS_URL
}

# Configure AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

# Data sources
data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

# Generate random password if not provided
resource "random_password" "admin_password" {
  count   = var.admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  admin_password         = var.admin_password != "" ? var.admin_password : random_password.admin_password[0].result
  cluster_admin_password = local.admin_password

  # Determine if cluster should be private
  private_cluster = var.cluster_type == "private"

  # Get the latest supported OpenShift version if not specified
  openshift_version = var.openshift_version != "" ? var.openshift_version : data.rhcs_versions.all.items[0].name
}

# Create account roles (if not already existing)
module "create_account_roles" {
  source  = "terraform-redhat/rosa-hcp/rhcs"
  version = "1.6.2"

  account_role_prefix    = "${var.cluster_name}-account"
  ocm_environment        = "production"
  rosa_openshift_version = local.openshift_version
  account_role_policies  = data.rhcs_policies.all_policies.account_role_policies
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  path                   = "/"
}

# Create operator roles
module "operator_roles" {
  source  = "terraform-redhat/rosa-hcp/rhcs"
  version = "1.6.2"

  operator_role_prefix   = "${var.cluster_name}-operator"
  account_role_prefix    = module.create_account_roles.account_role_prefix
  ocm_environment        = "production"
  rosa_openshift_version = local.openshift_version
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  path                   = "/"
}

# Create OIDC config
module "oidc_config_and_provider" {
  source  = "terraform-redhat/rosa-hcp/rhcs"
  version = "1.6.2"
  managed            = true
  installer_role_arn = module.create_account_roles.account_roles_arn["Installer"]
  tags               = var.tags
}

# Create the ROSA HCP cluster
resource "rhcs_cluster_rosa_hcp" "rosa_hcp_cluster" {
  name                   = var.cluster_name
  cloud_region           = var.region
  aws_account_id         = module.create_account_roles.aws_account_id
  aws_billing_account_id = module.create_account_roles.aws_account_id
  availability_zones     = var.availability_zones

  # OpenShift version
  version = local.openshift_version

  # Network configuration
  machine_cidr = var.machine_cidr
  service_cidr = var.service_cidr
  pod_cidr     = var.pod_cidr
  host_prefix  = var.host_prefix

  # Private cluster configuration
  private          = local.private_cluster
  aws_private_link = local.private_cluster

  # Compute configuration  
  replicas             = var.replicas
  compute_machine_type = var.compute_machine_type

  # AWS and OpenShift configuration
  aws_subnet_ids = local.private_cluster ? [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id,
    aws_subnet.private_subnets[2].id
  ] : []

  # OIDC Configuration
  sts = {
    operator_role_prefix = module.operator_roles.operator_role_prefix
    role_arn             = module.create_account_roles.account_roles_arn["Installer"]
    support_role_arn     = module.create_account_roles.account_roles_arn["Support"]
    instance_iam_roles = {
      master_role_arn = module.create_account_roles.account_roles_arn["ControlPlane"]
      worker_role_arn = module.create_account_roles.account_roles_arn["Worker"]
    }
  }

  oidc_config_id = module.oidc_config_and_provider.oidc_config_id

  # Wait for cluster to be ready
  wait_for_create_complete = true

  # Properties
  properties = {
    rosa_creator_arn = module.create_account_roles.account_roles_arn["Installer"]
  }

  lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }
}

# Create cluster admin user
resource "rhcs_cluster_rosa_hcp_admin_user" "cluster_admin" {
  cluster  = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  username = var.admin_username
  password = local.cluster_admin_password
}

# Configure Kubernetes provider to connect to the cluster
provider "kubernetes" {
  host     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.api_url
  username = rhcs_cluster_rosa_hcp_admin_user.cluster_admin.username
  password = rhcs_cluster_rosa_hcp_admin_user.cluster_admin.password
  insecure = false
}

# Create namespace for OpenShift AI
resource "kubernetes_namespace" "openshift_ai" {
  depends_on = [rhcs_cluster_rosa_hcp.rosa_hcp_cluster]

  metadata {
    name = "openshift-ai-operator"
  }
}

# Create namespace for OpenShift GitOps
resource "kubernetes_namespace" "openshift_gitops" {
  depends_on = [rhcs_cluster_rosa_hcp.rosa_hcp_cluster]

  metadata {
    name = "openshift-gitops-operator"
  }
}

# Deploy OpenShift AI Operator
resource "kubernetes_manifest" "openshift_ai_operator_group" {
  depends_on = [kubernetes_namespace.openshift_ai]

  manifest = {
    apiVersion = "operators.coreos.com/v1"
    kind       = "OperatorGroup"
    metadata = {
      name      = "openshift-ai-operator-group"
      namespace = "openshift-ai-operator"
    }
    spec = {
      targetNamespaces = ["openshift-ai-operator"]
    }
  }
}

resource "kubernetes_manifest" "openshift_ai_subscription" {
  depends_on = [kubernetes_manifest.openshift_ai_operator_group]

  manifest = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind       = "Subscription"
    metadata = {
      name      = "rhods-operator"
      namespace = "openshift-ai-operator"
    }
    spec = {
      channel             = "stable"
      name                = "rhods-operator"
      source              = "redhat-operators"
      sourceNamespace     = "openshift-marketplace"
      installPlanApproval = "Automatic"
    }
  }
}

# Deploy OpenShift GitOps Operator
resource "kubernetes_manifest" "openshift_gitops_operator_group" {
  depends_on = [kubernetes_namespace.openshift_gitops]

  manifest = {
    apiVersion = "operators.coreos.com/v1"
    kind       = "OperatorGroup"
    metadata = {
      name      = "openshift-gitops-operator-group"
      namespace = "openshift-gitops-operator"
    }
    spec = {
      targetNamespaces = ["openshift-gitops-operator"]
    }
  }
}

resource "kubernetes_manifest" "openshift_gitops_subscription" {
  depends_on = [kubernetes_manifest.openshift_gitops_operator_group]

  manifest = {
    apiVersion = "operators.coreos.com/v1alpha1"
    kind       = "Subscription"
    metadata = {
      name      = "openshift-gitops-operator"
      namespace = "openshift-gitops-operator"
    }
    spec = {
      channel             = "latest"
      name                = "openshift-gitops-operator"
      source              = "redhat-operators"
      sourceNamespace     = "openshift-marketplace"
      installPlanApproval = "Automatic"
    }
  }
}
