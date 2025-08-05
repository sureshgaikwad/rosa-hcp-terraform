## ROSA HCP Cluster Terraform Automation

This Terraform configuration automates the deployment of Red Hat OpenShift Service on AWS (ROSA) clusters using the Hosted Control Plane (HCP) architecture.

### Features

- **HCP Architecture**: Deploys ROSA clusters with Hosted Control Plane
- **Flexible Networking**: Supports both public and private (PrivateLink) cluster configurations
- **Automatic Role Management**: Creates necessary AWS IAM roles and OIDC configurations
- **Operator Deployment**: Automatically installs OpenShift AI and GitOps operators
- **Admin User Creation**: Creates a cluster admin user with configurable credentials
- **Complete VPC Setup**: For private clusters, creates VPC with public/private subnets and NAT gateways

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Red Hat Cloud Services token** - Set as environment variable `RHCS_TOKEN`
3. **Terraform** >= 1.0 installed
4. **ROSA CLI** installed and configured (optional, for verification)

### Required AWS Permissions

Your AWS credentials need the following permissions:
- IAM role creation and management
- VPC and networking resource management
- ROSA service permissions

### Environment Variables

Set these environment variables before running Terraform:

```bash
export RHCS_TOKEN="your-red-hat-cloud-services-token"
export RHCS_URL="https://api.openshift.com"
export AWS_REGION="us-east-1"
```

### Usage

1. **Clone and prepare**:
   ```bash
   git clone <this-repo>
   cd rosa-hcp-terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Configure variables**:
   Edit `terraform.tfvars` with your desired configuration:
   ```hcl
   cluster_name = "my-rosa-cluster"
   region = "us-east-1"
   cluster_type = "public"  # or "private" for PrivateLink
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access your cluster**:
   ```bash
   # Get the admin password
   terraform output -raw cluster_admin_password
   
   # Login to the cluster
   oc login $(terraform output -raw api_url) \
     -u $(terraform output -raw cluster_admin_username) \
     -p $(terraform output -raw cluster_admin_password)
   ```

### Configuration Options

#### Cluster Types

- **Public Cluster** (`cluster_type = "public"`):
  - Standard ROSA cluster with public API endpoint
  - Nodes in public subnets with internet access
  - Suitable for development and testing

- **Private Cluster** (`cluster_type = "private"`):
  - PrivateLink-enabled cluster with private API endpoint
  - Nodes in private subnets with NAT gateway access
  - Enhanced security for production workloads

#### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | Name of the ROSA cluster | `rosa-hcp-cluster` |
| `cluster_type` | `public` or `private` | `public` |
| `region` | AWS region | `us-east-1` |
| `openshift_version` | OpenShift version | `4.14.15` |
| `compute_machine_type` | EC2 instance type for workers | `m5.xlarge` |
| `replicas` | Number of worker nodes | `3` |
| `admin_username` | Cluster admin username | `cluster-admin` |
| `admin_password` | Cluster admin password | Auto-generated |

### Installed Operators

The automation automatically installs:

1. **OpenShift AI Operator** (`rhods-operator`):
   - Namespace: `openshift-ai-operator`
   - Channel: `stable`
   - Auto-approval enabled

2. **OpenShift GitOps Operator** (`openshift-gitops-operator`):
   - Namespace: `openshift-gitops-operator`
   - Channel: `latest`
   - Auto-approval enabled

### Outputs

After successful deployment, you'll get:

- Cluster ID and name
- API and console URLs
- Admin username and password
- OIDC configuration details
- Role prefixes for troubleshooting

### Cleanup

To destroy the cluster and all resources:

```bash
terraform destroy
```

**Note**: This will permanently delete your cluster and all data within it.

### Troubleshooting

1. **Token Issues**: Ensure your RHCS token is valid and has cluster creation permissions
2. **AWS Permissions**: Verify your AWS credentials have sufficient IAM permissions
3. **Quota Limits**: Check AWS service quotas for EC2 instances in your region
4. **Version Compatibility**: Ensure the OpenShift version is supported in your region

### Support

For issues with:
- **Terraform configuration**: Check the Terraform logs and AWS CloudTrail
- **ROSA cluster**: Use `rosa logs cluster <cluster-name>` for cluster-specific issues
- **Operators**: Check the operator installation status in the OpenShift console

### Security Considerations

- Store sensitive variables (like passwords) in secure secret management systems
- Use private clusters for production workloads
- Regularly update OpenShift versions for security patches
- Monitor cluster access logs and implement appropriate RBAC policies
