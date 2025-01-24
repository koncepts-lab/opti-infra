# Create a network interface
resource "azurerm_network_interface" "nic" {
  name                = "main-nic"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.networking.vm_subnet_id["1"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    terraform = "true"
    env       = "${local.prefix}-nic"
  }
}

# Create a VM
resource "azurerm_linux_virtual_machine" "app_server" {
  name                = "main-vm"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  # size                = "Standard_DS1_v2"
  size                = "Standard_D2alds_v6"
  admin_username      = "testadmin"
  # admin_password = "Password1234!"
  # disable_password_authentication = false
  # zone = local.availability_zones[0]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "testadmin"
    public_key = tls_private_key.internal_key.public_key_openssh
  }
  
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    # sku       = "20.04-LTS"
    version   = "latest"
  }

  timeouts {
    create = "45m"
    delete = "30m"
  }
}

# Create Storage Account for App Data
resource "azurerm_storage_account" "app_data" {
  name                     = "appdata${random_string.unique.result}"
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  blob_properties {
    versioning_enabled = true
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    terraform = "true"
    env       = "${local.prefix}-app-dt-sa"
  }
}

# Create Containers for App Data
resource "azurerm_storage_container" "app_data" {
  name                  = "application-data"
  storage_account_name  = azurerm_storage_account.app_data.name
  container_access_type = "private"
}

# Create Storage Account for Backups
resource "azurerm_storage_account" "backup" {
  name                     = "backup${random_string.unique.result}"
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  
  blob_properties {
    versioning_enabled = true
    container_delete_retention_policy {
      days = 30
    }
  }

tags = {
    terraform = "true"
    env       = "${local.prefix}-bk-dt-sa"
  }
}

# Create Containers for Backups
resource "azurerm_storage_container" "backup" {
  name                  = "system-backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# Add network rules for storage accounts
resource "azurerm_storage_account_network_rules" "app_data_rules" {
  storage_account_id = azurerm_storage_account.app_data.id
  default_action     = "Allow"
  virtual_network_subnet_ids = [
    module.networking.vm_subnet_id["1"]
  ]
  bypass = ["Metrics", "Logging", "AzureServices"]
}

resource "azurerm_storage_account_network_rules" "backup_rules" {
  storage_account_id = azurerm_storage_account.backup.id
  default_action     = "Allow"
  virtual_network_subnet_ids = [
    module.networking.vm_subnet_id["1"]
  ]
  bypass = ["Metrics", "Logging", "AzureServices"]
}