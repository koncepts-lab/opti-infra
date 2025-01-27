# Opti Infrastructure Terraform Components
# Azure Infrastructure Deployment

This repository contains the Terraform configuration for OII's Azure infrastructure deployment, mirroring the existing AWS architecture. The infrastructure is designed for high availability, security, and scalability.

## Infrastructure Overview

### Network Architecture

The network is distributed across 3 Availability Zones with a total of 8 subnets:
- 6 active subnets (2 per AZ):
  - Virtual Machine subnet
  - NAT Gateway subnet
- 2 reserved subnets for future expansion

### Compute Resources

#### Virtual Machine
- Single `app_server` deployed in AZ-1
- Private IP configuration
- Access managed through Jumpbox

#### Jumpbox Configuration
- Fixed IP address for consistent and reliable access to the Jumpbox
- SSH key-based authentication
- Functions as secure entry point for app_server management

### Network Security

#### NAT Gateway Setup
- 3 NAT Gateways deployed across Availability Zones
- Configured for high availability and redundancy

#### Load Balancer Configuration
- Public-facing load balancer
- Backend pool configured with app_server NIC
- Active health monitoring
- SSL termination for oi-portal.com
- Certificate stored in Azure Key Vault

### Storage Infrastructure

Three dedicated storage accounts:
1. app_data: Primary application storage
2. backup_data: Backup retention
3. logs: Load Balancer logging

### Security Measures

- Private network architecture
- Secure Jumpbox access
- Azure Key Vault SSL certificate management
- Network segmentation across zones

### Scalability Features

- 2 reserved subnets for expansion
- Load Balancer configured for additional backends
- Distributed NAT Gateway architecture

## Access Information

### Production Environment
- Domain: oi-portal.com
- Jumpbox Access:
  - IP: 172.191.92.66
  - Username: jumpboxadmin

## Architecture Diagram

```
[Internet] --> [Load Balancer (SSL)] --> [app_server]
                     ^
                     |
[Jumpbox] ----------+
```

## Security Notes

1. All production access must route through the Jumpbox
2. SSL certificates are managed via Azure Key Vault
3. Private networking is enforced for all internal resources

## Maintenance Guidelines

1. Regular monitoring of NAT Gateway health
2. Storage account capacity monitoring
3. SSL certificate renewal tracking
4. Load Balancer logs review

## Future Expansion

The infrastructure supports horizontal scaling through:
1. Reserved subnet space
2. Load Balancer backend pool expansion
3. Distributed NAT Gateway architecture

## Deployment Instructions

### Prerequisites
- Terraform >= 1.0.0
- Azure CLI
- Azure subscription and credentials configured

### Required Secrets
Create a `secrets.tfvars` file with the following variables:
```hcl
jumpbox_admin_username   = "your_admin_username"
jumpbox_admin_password   = "your_admin_password"
```

Add `*.tfvars` to `.gitignore` to prevent committing secrets:
```bash
echo "*.tfvars" >> .gitignore
```

### Setup Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/koncepts-lab/opti-infra.git
   cd opti-infra\terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the deployment plan:
   ```bash
   terraform plan -var-file="secrets.tfvars"
   ```

4. Apply the infrastructure:
   ```bash
   terraform apply -var-file="secrets.tfvars"
   ```
   Confirm by typing `yes` when prompted.

### Destroying Infrastructure
To tear down the infrastructure:
```bash
terraform destroy -var-file="secrets.tfvars"
```
Confirm by typing `yes` when prompted.

### Important Notes
- Always review the plan before applying
- Keep terraform state files secure
- Run `terraform init` after pulling new changes
- Use workspaces for different environments

## Support

For infrastructure support or questions, please contact the DevOps team.
