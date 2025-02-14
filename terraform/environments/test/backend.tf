terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstatetest"   # Note: test specific
    container_name      = "tfstate"
    key                 = "test.terraform.tfstate"  # Note: test specific
    use_azuread_auth    = true
    subscription_id     = "your-subscription-id"
    tenant_id          = "your-tenant-id"
  }
}