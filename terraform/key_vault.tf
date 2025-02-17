# Create Azure Key Vault for storing sensitive information
resource "azurerm_key_vault" "vault" {
  name                = "${var.prefix}-${var.env}-vault"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  tags = {
    environment = var.env
    purpose     = "key-management"
  }
}

# Get the current Azure CLI credentials
data "azurerm_client_config" "current" {}

# Service Principal Policy (from error message)
resource "azurerm_key_vault_access_policy" "service_principal" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "f42b97e0-333c-41e1-9150-dc94a90f29df"  # Object ID from error message

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update"
  ]

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update",
    "Import", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover",
    "Backup", "Restore"
  ]
}

# App Gateway Identity Policy
resource "azurerm_key_vault_access_policy" "app_gateway_identity_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_gateway_identity.principal_id

  certificate_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}

# Current User Policy
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import",
    "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers",
    "SetIssuers", "DeleteIssuers", "Backup", "Restore", "Recover"
  ]

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", 
    "Import", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", 
    "Backup", "Restore"
  ]
}

# The Key Vault will be created first
# All access policies will be created next
# Only then will the certificates be created
# Each identity (service principal, app gateway, current user) has exactly one policy with the right permissions