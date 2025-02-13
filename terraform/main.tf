# Configure Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration - this should be different for each environment
  backend "azurerm" {
    # These values should be overridden by backend configuration in each environment
  }
}

provider "azurerm" {
  features {}

  # If using different subscriptions per environment, these can be set via variables
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Networking module with environment-specific variables
module "networking" {
  source = "./modules/networking"

  # Pass through environment-specific variables
  resource_group_name = var.resource_group_name
  location           = var.location
  env                = var.env
  prefix             = var.prefix
  redundancy         = var.redundancy
}

# Root level local variables
locals {
  common_tags = {
    Environment = var.env
    Project     = var.product
    ManagedBy   = "Terraform"
  }
}



















