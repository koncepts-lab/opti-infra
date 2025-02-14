# =============================================================================
# Application Server Configuration
# Purpose: Deploys the main application server with associated storage and networking
# =============================================================================

# -----------------------------------------------------------------------------
# Network Security Group
# Defines security rules for the application server
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "appserver_nsg" {
  name                = "${local.prefix}-appserver-nsg"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  # Allow HTTPS inbound
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  # Allow internal communication
  security_rule {
    name                       = "AllowInternalAll"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    Name = "${local.prefix}-appserver-nsg"
  }
}

# -----------------------------------------------------------------------------
# Network Interface
# Creates the primary network interface for the app server
# -----------------------------------------------------------------------------
resource "azurerm_network_interface" "app_server_nic" {
  name                = "${local.prefix}-appserver-nic"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.networking.vm_subnet_id["1"]  # Using first AZ
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "${local.prefix}-appserver-nic"
  }
}

# -----------------------------------------------------------------------------
# Network Security Group Association
# Links the NSG to the network interface
# -----------------------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "app_nsg_association" {
  network_interface_id      = azurerm_network_interface.app_server_nic.id
  network_security_group_id = azurerm_network_security_group.appserver_nsg.id
}

# -----------------------------------------------------------------------------
# Virtual Machine
# Creates the application server with both internal and external SSH key access
# -----------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "app_server" {
  name                = "${local.prefix}-appserver"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  size                = "Standard_D8ps_v5"  # ARM-based VM
  admin_username      = var.app_server_admin_username

  # Configure both provided (external) and internal SSH keys
  dynamic "admin_ssh_key" {
    for_each = [
      {
        username   = var.app_server_admin_username
        public_key = var.app_server_ssh_key  # External key for CI/CD access
      },
      {
        username   = var.app_server_admin_username
        public_key = tls_private_key.internal_key.public_key_openssh  # Internal key for infrastructure communication
      }
    ]
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  # Network interface configuration
  network_interface_ids = [
    azurerm_network_interface.app_server_nic.id
  ]

  # OS disk configuration
  os_disk {
    name                 = "${local.prefix}-appserver-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"  # Premium SSD for better performance
    disk_size_gb         = 50
  }

  # OS image configuration - RedHat Enterprise Linux
  source_image_reference {
  publisher = "RedHat"
  offer     = "RHEL"
  sku       = "9_5-lvm-gen2"
  version   = "latest"
}


  plan {
    name      = "8_6"
    product   = "RHEL"
    publisher = "RedHat"
  }

  # Initialize the app server with required software and configuration
  custom_data = base64encode(file("${path.module}/userdata/appserver-init.sh"))

  tags = {
    Name          = "${local.prefix}-appserver-instance"
    ansible_group = "appserver"
  }
}

# -----------------------------------------------------------------------------
# Database Storage
# Creates and attaches a managed disk for database storage
# -----------------------------------------------------------------------------
resource "azurerm_managed_disk" "db_disk" {
  name                 = "${local.prefix}-db-disk"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  storage_account_type = "Premium_LRS"  # Premium SSD for database performance
  create_option        = "Empty"
  disk_size_gb         = 100

  tags = {
    Name = "${local.prefix}-appserver-db-disk"
  }
}

# -----------------------------------------------------------------------------
# Database Disk Attachment
# Attaches the database disk to the app server
# -----------------------------------------------------------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "db_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.db_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.app_server.id
  lun                = "10"  # Logical Unit Number for disk identification
  caching            = "ReadWrite"
}

# -----------------------------------------------------------------------------
# Storage Accounts
# Creates storage accounts for backups and application data
# -----------------------------------------------------------------------------
# Storage Account for Backups
resource "azurerm_storage_account" "backup_storage" {
  name                     = replace("${local.prefix}backups", "-", "")
  resource_group_name      = module.networking.resource_group_name
  location                = module.networking.resource_group_location
  account_tier            = "Standard"
  account_replication_type = "GRS"  # Geo-redundant storage for backup safety

  tags = {
    Name = "${local.prefix}-backups-storage"
  }
}

# Storage Account for Application Data
resource "azurerm_storage_account" "app_data_storage" {
  name                     = replace("${local.prefix}appdata", "-", "")
  resource_group_name      = module.networking.resource_group_name
  location                = module.networking.resource_group_location
  account_tier            = "Standard"
  account_replication_type = "LRS"  # Locally redundant storage for app data

  tags = {
    Name = "${local.prefix}-app-data-storage"
  }
}

# -----------------------------------------------------------------------------
# Storage Containers
# Creates containers within the storage accounts
# -----------------------------------------------------------------------------
resource "azurerm_storage_container" "backup_container" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "app_data_container" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.app_data_storage.name
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Application Gateway Backend Pool Association
# Associates the app server with the Application Gateway backend pool
# -----------------------------------------------------------------------------
resource "azurerm_app_configuration_key" "backend_pool" {
  configuration_store_id = azurerm_application_gateway.app_gateway.id
  key                   = "${local.prefix}-backend-pool"
  value                 = azurerm_network_interface.app_server_nic.private_ip_address
  
  depends_on = [
    azurerm_application_gateway.app_gateway,
    azurerm_network_interface.app_server_nic
  ]
}

