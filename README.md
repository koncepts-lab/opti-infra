# Opti Infrastructure Terraform Azure Deployment

## Overview

This repository contains the Terraform configuration for deploying a robust, secure, and scalable infrastructure on Microsoft Azure. The infrastructure is designed to provide high availability, strong security, and flexible scalability across multiple environments. This deployment represents a migration from AWS to Azure, with architectural adjustments to leverage Azure-native capabilities.

## Migration Changes

### Key Infrastructure Changes

1. **DNS to IP Address Migration**
   - Moved from AWS DNS-based addressing to Azure IP-based addressing
   - Jumpbox now uses public IP instead of public DNS
   - App server uses private IP instead of private DNS
   - Justification: Better alignment with Azure's networking model and simplified DNS management

2. **Authentication Updates**
   - Replaced AWS profile-based authentication with Azure subscription and tenant ID
   - Added explicit admin username variables
   - Enhanced SSH key management with separate keys for jumpbox and app server
   - Justification: Compliance with Azure's security model and more granular access control

3. **Resource Configuration**
   - Added detailed VM size specifications
   - Introduced OS disk configuration options
   - Enhanced redundancy validation (1-3 zones)
   - Justification: Leverage Azure's flexible VM sizing and storage options

### Infrastructure Architecture

### Network Design

- **Availability Zones**: Distributed across 3 Availability Zones
- **Subnet Configuration**: 
  - 6 active subnets (2 per Availability Zone)
    - Virtual Machine subnets
    - NAT Gateway subnets
  - 2 reserved subnets for future expansion

### Key Components

1. **Compute Resources**
   - Single `app_server` deployed in Availability Zone 1
   - Private IP configuration
   - Jumpbox with configurable size (default: Standard_B1s)
   - Customizable OS disk size and type

2. **Network Security**
   - 3 NAT Gateways for high availability
   - Application Gateway with SSL termination
   - Comprehensive Network Security Groups (NSGs)

3. **Storage Infrastructure**
   - Three dedicated storage accounts:
     - `app_data`: Primary application storage
     - `backup_data`: Backup retention
     - `logs`: Load balancer and application logging

4. **Security Measures**
   - Azure Key Vault for certificate and secret management
   - Private network architecture
   - Enhanced key-based Jumpbox access with separate key pairs

## Prerequisites

### System Requirements
- Terraform >= 1.0.0
- Azure CLI
- Active Azure subscription

### Authentication
Required credentials (in secrets.tfvars):
- `subscription_id`: Azure subscription ID
- `tenant_id`: Azure tenant ID
- `jumpbox_admin_username`: Admin username for jumpbox
- `jumpbox_ssh_key`: SSH public key for jumpbox access
- `app_server_admin_username`: Admin username for app server

## Repository Structure

```
opti-infra/
├── terraform/
│   ├── environments/           # Environment-specific configurations
│   │   ├── dev/
│   │   ├── test/
│   │   └── prod/
│   ├── modules/                # Reusable Terraform modules
│   │   └── networking/
│   ├── secrets/                # Sensitive configuration (gitignored)
│   ├── templates/              # Configuration templates
│   ├── userdata/               # Initialization scripts
│   └── main.tf                 # Primary Terraform configuration
```

## Deployment Instructions

### 1. Prepare Secrets Configuration

1. Navigate to the secrets directory:
   ```bash
   cd terraform/secrets
   ```

2. Copy the secrets template:
   ```bash
   cp secrets.tfvars.example secrets.tfvars
   ```

3. Edit `secrets.tfvars` with your Azure-specific values:
   ```bash
   nano secrets.tfvars
   ```

#### Required Configuration Values
- **Azure Authentication**
  - `subscription_id`: Your Azure subscription ID
  - `tenant_id`: Your Azure tenant ID

- **VM Access**
  - `jumpbox_admin_username`: Jumpbox admin username
  - `jumpbox_ssh_key`: Jumpbox SSH public key
  - `app_server_admin_username`: App server admin username
  - `app_server_ssh_key`: App server SSH public key

- **Key Vault Access**
  - `key_vault_object_id`: Key Vault access object ID

#### Optional Configuration
- Storage access keys
- Email service credentials

### 2. Initialize Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init
```

### 3. Select Environment Workspace

```bash
# Create and select workspace
terraform workspace new dev
terraform workspace select dev
```

### 4. Plan Infrastructure

```bash
# Review planned changes
terraform plan \
  -var-file="environments/dev/terraform.tfvars" \
  -var-file="secrets/secrets.tfvars"
```

### 5. Apply Infrastructure

```bash
# Deploy infrastructure
terraform apply \
  -var-file="environments/dev/terraform.tfvars" \
  -var-file="secrets/secrets.tfvars"
```

## Environment Management

### Workspace Commands

```bash
# Development Environment
terraform workspace new dev
terraform workspace select dev
terraform plan -var-file="environments/dev/terraform.tfvars"

# Testing Environment
terraform workspace new test
terraform workspace select test
terraform plan -var-file="environments/test/terraform.tfvars"

# Production Environment
terraform workspace new prod
terraform workspace select prod
terraform plan -var-file="environments/prod/terraform.tfvars"
```

## Destroying Infrastructure

⚠️ **Caution**: This will remove all resources in the current workspace.

```bash
terraform destroy \
  -var-file="environments/dev/terraform.tfvars" \
  -var-file="secrets/secrets.tfvars"
```

## Security Guidelines

1. Never commit `secrets.tfvars` to version control
2. Use strong, unique passwords
3. Regularly rotate access keys
4. Limit SSH access to trusted IP ranges
5. Monitor Key Vault and storage account logs


## Azure-Specific Maintenance Recommendations

- Monitor NAT Gateway allocation and scaling
- Review Network Security Group rules regularly
- Track VM performance metrics
- Monitor public IP address usage
- Audit Key Vault access logs
- Regular review of RBAC assignments

## Support

For infrastructure support or questions about the Azure migration, please contact the DevOps team.