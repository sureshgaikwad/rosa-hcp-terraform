variable "cluster_name" {
  description = "Name of the ROSA cluster"
  type        = string
  default     = "sgaikwad-hcp-cluster"
}

variable "aws_region" {
  description = "AWS region for the cluster"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_type" {
  description = "Type of cluster: 'private' for PrivateLink or 'public' for public cluster"
  type        = string
  default     = "public"
  validation {
    condition     = contains(["private", "public"], var.cluster_type)
    error_message = "Cluster type must be either 'private' or 'public'."
  }
}

variable "openshift_version" {
  description = "OpenShift version for the cluster"
  type        = string
  default     = "4.19.4"
}

variable "compute_machine_type" {
  description = "Instance type for compute nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "replicas" {
  description = "Number of compute nodes"
  type        = number
  default     = 3
}

variable "aws_availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "machine_cidr" {
  description = "CIDR block for the cluster VPC"
  type        = string
  default     = "10.0.0.0/16"
}

#variable "aws_subnet_ids" {
#  description = "List of subnet IDs"
#  type        = list(string)
#}


variable "service_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "172.30.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.128.0.0/14"
}

variable "host_prefix" {
  description = "Host prefix for pod CIDR"
  type        = number
  default     = 23
}

variable "admin_username" {
  description = "Username for cluster admin"
  type        = string
  default     = "cluster-admin"
}

variable "admin_password" {
  description = "Password for cluster admin (if not provided, will be generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
