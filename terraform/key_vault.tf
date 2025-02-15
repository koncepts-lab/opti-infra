# Create Azure Key Vault for storing sensitive information
resource "azurerm_key_vault" "vault" {
  name                        = "${var.prefix}-${var.env}-vault"
  location                    = module.networking.resource_group_location
  resource_group_name         = module.networking.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  # Allow the currently authenticated Azure CLI user to manage the Key Vault
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

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
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey"
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]
  }

  # Add access policy for the jumpbox's managed identity (if using)
  dynamic "access_policy" {
    for_each = var.env == "prod" ? [1] : []  # Only in prod
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = azurerm_linux_virtual_machine.jumpbox.identity[0].principal_id

      secret_permissions = [
        "Get", "List",
      ]
    }
  }

  tags = {
    environment = var.env
    purpose     = "key-management"
  }
}

# Get the current Azure CLI credentials
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Get",
    "List",
    "Create", 
    "Delete",
    "Update",
    "Import",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    "Backup",
    "Restore",
    "Recover"
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

resource "azurerm_key_vault_access_policy" "terraform_access" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.key_vault_object_id  # Using the variable from secrets.tfvars

  certificate_permissions = [
    "Get",
    "List",
    "Create", 
    "Delete",
    "Update",
    "Import",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

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

resource "azurerm_key_vault_access_policy" "app_gateway_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_gateway_identity.principal_id

  certificate_permissions = [
    "Get",
    "List"
  ]

  secret_permissions = [
    "Get",
    "List"
  ]
}