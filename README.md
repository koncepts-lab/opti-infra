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

## Architecture Overview

### Network Design

- **Availability Zones**: Distributed across availability zones based on redundancy parameter
- **Subnet Configuration**: 
  - VM subnets (equivalent to AWS public subnets)
  - NAT Gateway subnets (equivalent to AWS private subnets)
  - Application Gateway subnet
- **CIDR Allocation**: Maintains the same IP address scheme as AWS implementation

### Key Components

1. **Compute Resources**
   - App server deployed in private subnet with managed disk for database storage
   - Jumpbox with public IP for secure administrative access
   - Both VMs use RedHat Enterprise Linux (RHEL) images

2. **Network Security**
   - Network Security Groups (NSGs) for network traffic control
   - NAT Gateways for outbound connectivity from private subnets
   - Application Gateway with SSL termination and WAF protection

3. **Storage Infrastructure**
   - Three dedicated storage accounts:
     - `app_data`: Primary application storage
     - `backup_data`: Backup retention
     - `logs`: Load balancer and application logging

4. **Security Measures**
   - Azure Key Vault for certificate and secret management
   - Private network architecture
   - Enhanced key-based SSH access with separate key pairs

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
- `app_server_ssh_key`: SSH public key for app server access
- `key_vault_object_id`: Object ID for Key Vault access

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

#### Finding Required Azure IDs

Get your Azure Subscription ID and Tenant ID:
```bash
# List all subscriptions
az account list --output table

# Get details of the current subscription
az account show --output json
```

Find your Object ID (for Key Vault access):
```bash
# For current user
az ad signed-in-user show --query id --output tsv

# For a service principal
az ad sp show --id <app-id> --query id --output tsv

# For another user
az ad user show --id user@example.com --query id --output tsv
```

Find resource IDs for importing existing resources:
```bash
# Key Vault
az keyvault show --name <vault-name> --resource-group <resource-group> --query id --output tsv

# Key Vault Secret
az keyvault secret show --name <secret-name> --vault-name <vault-name> --query id --output tsv
```

## Deployment Instructions

### 1. Set up Azure Storage for Terraform State

First, create the Azure storage account to store Terraform state:

```bash
# Create resource group for Terraform state
az group create --name terraform-state-rg --location eastus

# Create storage account
az storage account create \
  --name oiitfstatedev \
  --resource-group terraform-state-rg \
  --sku Standard_LRS

# Create container for Terraform state
az storage container create \
  --name tfstate \
  --account-name oiitfstatedev
```

### 2. Prepare Secrets Configuration

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

### 3. Initialize Terraform

```bash
# Navigate to terraform directory
cd terraform

# Navigate to the correct environment directory
cd terraform/environments/dev

# Initialize Terraform with backend configuration
terraform init \
  -backend-config="environments/dev/backend.tf" \
  -reconfigure
```

### 4. Select Environment Workspace

```bash
# Create and select workspace
terraform workspace new dev
terraform workspace select dev
```

### 5. Plan Infrastructure

```bash
# Review planned changes
terraform plan \
  -var-file="environments/dev/terraform.tfvars" \
  -var-file="secrets/secrets.tfvars"
```

### 6. Apply Infrastructure

```bash
# Deploy infrastructure
terraform apply \
  -var-file="environments/dev/terraform.tfvars" \
  -var-file="secrets/secrets.tfvars"
```

## Environment Management

### Working with Different Environments

```bash
# Development Environment
# Create storage account (if not exists)
az storage account create --name oiitfstatedev --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name oiitfstatedev

# Initialize and plan
terraform init -backend-config="environments/dev/backend.tf" -reconfigure
terraform plan -var-file="environments/dev/terraform.tfvars" -var-file="secrets/secrets.tfvars"

# Testing Environment
# Create storage account (if not exists)
az storage account create --name oiitfstatetest --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name oiitfstatetest

# Initialize and plan
terraform init -backend-config="environments/test/backend.tf" -reconfigure
terraform plan -var-file="environments/test/terraform.tfvars" -var-file="secrets/secrets.tfvars"

# Production Environment
# Create storage account (if not exists)
az storage account create --name oiitfstateprod --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name oiitfstateprod

# Initialize and plan
terraform init -backend-config="environments/prod/backend.tf" -reconfigure
terraform plan -var-file="environments/prod/terraform.tfvars" -var-file="secrets/secrets.tfvars"
```

## Accessing the Infrastructure

### Jumpbox Access
```bash
ssh <jumpbox_admin_username>@<jumpbox_public_ip> -i /path/to/private_key
```

### App Server Access (via Jumpbox)
```bash
ssh <app_server_admin_username>@<app_server_private_ip> -i ~/.ssh/oii-internal-key-rsa
```

## Key Outputs

After applying the Terraform configuration, you'll get these important outputs:

- `jumpbox_public_ip`: Public IP address of the jumpbox
- `app_server_private_ip`: Private IP of the app server
- `jumpbox_private_ip`: Private IP address of the jumpbox
- `dns_zone_nameservers`: DNS zone nameservers
- `certificate_thumbprint`: SSL certificate thumbprint
- `internal_ssh_key`: Internal SSH key for infrastructure access

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

## Troubleshooting

### Importing Existing Resources

If you encounter issues with resources already existing in Azure, you may need to import them into Terraform state:

```bash
# Import Key Vault secrets
terraform import azurerm_key_vault_secret.internal_ssh_key "https://your-key-vault-url/secrets/internal-ssh-private-key/version"
terraform import azurerm_key_vault_secret.internal_ssh_public_key "https://your-key-vault-url/secrets/internal-ssh-public-key/version"

# Import Key Vault access policies
terraform import "azurerm_key_vault_access_policy.current_user" "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.KeyVault/vaults/<vault-name>/objectId/<object-id>"

# Import diagnostic settings
terraform import azurerm_monitor_diagnostic_setting.app_gateway_diag "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/applicationGateways/<gateway-name>|<diagnostic-setting-name>"
```

You can also add import blocks to your Terraform files for consistent management:

```terraform
import {
  to = azurerm_key_vault_secret.internal_ssh_key
  id = "https://your-key-vault-url/secrets/internal-ssh-private-key/version"
}
```

## Support

For infrastructure support or questions about the Azure deployment, please contact the DevOps team.