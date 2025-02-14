terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstateprod"   # Note: prod specific
    container_name      = "tfstate"
    key                 = "prod.terraform.tfstate"  # Note: prod specific
    use_azuread_auth    = true
    subscription_id     = "your-subscription-id"
    tenant_id          = "your-tenant-id"
  }
}