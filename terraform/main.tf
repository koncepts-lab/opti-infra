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
}

provider "azurerm" {
  # subscription_id = "cbae65ed-46b5-4899-8f50-0a64777cbfea"
  # tenant_id       = "3970c661-584d-4ad9-9a2b-60f2878efac7"
  features {}
}

module "networking" {
  source     = "./modules/networking"
}

locals {
  prefix      = "${var.product}-${var.env}"
}




















