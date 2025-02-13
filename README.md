# Opti Infrastructure Terraform Azure Deployment

## Overview

This repository contains the Terraform configuration for deploying a robust, secure, and scalable infrastructure on Microsoft Azure. The infrastructure is designed to provide high availability, strong security, and flexible scalability across multiple environments.

## Infrastructure Architecture

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
   - Jumpbox for secure administrative access

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
   - Secure, key-based Jumpbox access

## Prerequisites

### System Requirements
- Terraform >= 1.0.0
- Azure CLI
- Active Azure subscription

### Authentication
- Azure subscription credentials
- Configured Azure CLI access

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

3. Edit `secrets.tfvars` with your specific values:
   ```bash
   nano secrets.tfvars
   ```

#### Required Configuration Values
- **Azure Authentication**
  - `subscription_id`: Your Azure subscription ID
  - `tenant_id`: Your Azure tenant ID

- **App Server Access**
  - `app_server_admin_username`: Admin username
  - `app_server_ssh_key`: SSH public key

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

## Maintenance Recommendations

- Regularly review NAT Gateway health
- Monitor storage account capacity
- Track SSL certificate expiration
- Audit Application Gateway logs
- Perform periodic security assessments

## Scalability Features

- Reserved subnet space for expansion
- Distributed NAT Gateway architecture
- Configurable load balancer backend pool

## Support

For infrastructure support or questions, please contact the DevOps team.