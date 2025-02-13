terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstatedev"
    container_name      = "tfstate"
    key                 = "dev.terraform.tfstate"
  }
}