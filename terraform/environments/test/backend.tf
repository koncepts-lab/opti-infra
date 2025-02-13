terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstatetest"
    container_name      = "tfstate"
    key                 = "test.terraform.tfstate"
  }
}