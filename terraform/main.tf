# =============================================================================
# Main Terraform Configuration File
# Purpose: Defines core infrastructure setup for Azure environment
# =============================================================================

# Configure Azure Provider
terraform {
  # Define required providers with specific versions
  required_providers {
    # Azure Resource Manager provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    # Random provider for generating unique names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    # TLS provider for certificate and key generation
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration - placeholder for environment-specific settings
  backend "azurerm" {
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    # Add specific feature flags here if needed
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }

  # Authentication configuration
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# =============================================================================
# Local Variables
# =============================================================================

locals {
  # Combine prefix and environment for resource naming
  prefix = "${var.prefix}-${var.env}"

  # Common tags to be applied to all resources
  common_tags = {
    Environment = var.env
    Project     = var.product
    ManagedBy   = "Terraform"
    CreatedDate = timestamp()
  }
}

# =============================================================================
# Core Infrastructure Modules
# =============================================================================

# Networking Module
# Handles all network-related resources including VNet, Subnets, NSGs
module "networking" {
  source = "./modules/networking"

  # Core Settings
  resource_group_name = var.resource_group_name
  location           = var.location
  env                = var.env
  prefix             = var.prefix
  redundancy         = var.redundancy

  # Network Configuration
  address_space     = var.address_space
  vm_subnet_prefix  = var.vm_subnet_prefix
  nat_subnet_prefix = var.nat_subnet_prefix

  # Storage Configuration
  storage_account_tier     = var.storage_account_tier
  backup_replication_type  = var.backup_replication_type
  appdata_replication_type = var.appdata_replication_type

  # Application Gateway Configuration
  appgw_subnet_prefix = var.appgw_subnet_prefix
  app_gateway_sku_name   = var.app_gateway_sku_name
  app_gateway_sku_tier   = var.app_gateway_sku_tier
  app_gateway_capacity   = var.app_gateway_capacity
}

# =============================================================================
# Optional Terraform State Storage (if using local backend)
# =============================================================================

# Only create if not using remote backend
resource "azurerm_storage_account" "terraform_state" {
  count                    = var.create_state_storage ? 1 : 0
  name                     = "${replace(local.prefix, "-", "")}tfstate"
  resource_group_name      = var.resource_group_name
  location                = var.location
  account_tier            = "Standard"
  account_replication_type = "GRS"
 
  tags = merge(local.common_tags, {
    Purpose = "terraform-state"
  })
}

resource "azurerm_storage_container" "terraform_state_container" {
  count                 = var.create_state_storage ? 1 : 0
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state[0].name
  container_access_type = "private"
}

# =============================================================================
# Outputs
# =============================================================================

output "resource_group_name" {
  value       = var.resource_group_name
  description = "The name of the resource group"
}