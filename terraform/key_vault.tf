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

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
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