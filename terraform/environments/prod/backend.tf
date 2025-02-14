terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "oiitfstateprod"   # Note: prod specific
    container_name      = "tfstate"
    key                 = "prod.terraform.tfstate"  # Note: prod specific
    use_azuread_auth    = true
    subscription_id     = "cbae65ed-46b5-4899-8f50-0a64777cbfea"
    tenant_id          = "3970c661-584d-4ad9-9a2b-60f2878efac7"
  }
}