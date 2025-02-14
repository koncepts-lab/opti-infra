terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstatedev"    # Note: dev specific
    container_name      = "tfstate"
    key                 = "dev.terraform.tfstate"  # Note: dev specific
    use_azuread_auth    = true
    subscription_id     = "your-subscription-id"
    tenant_id          = "your-tenant-id"
  }
}