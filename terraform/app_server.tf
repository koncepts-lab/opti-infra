# Network Security Group (NSG) for app server
# This is equivalent to AWS Security Group (aws_security_group)
# In Azure, NSGs can be attached to subnets or network interfaces
resource "azurerm_network_security_group" "appserver_nsg" {
  name                = "${local.prefix}-appserver-nsg"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  # Allow HTTPS inbound - Port 443
  # Equivalent to aws_vpc_security_group_ingress_rule for HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001  # Lower number = higher priority
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  # Allow all internal communication
  # Equivalent to aws_vpc_security_group_ingress_rule for internal traffic
  security_rule {
    name                       = "AllowInternalAll"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"  # All protocols
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "VirtualNetwork"  # Only within VNet
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    Name = "${local.prefix}-appserver-nsg"
  }
}

# Network Interface for app server
# This is the Azure equivalent of AWS ENI (Elastic Network Interface)
resource "azurerm_network_interface" "app_server_nic" {
  name                = "${local.prefix}-appserver-nic"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.networking.vm_subnet_id["1"]  # Using first AZ
    private_ip_address_allocation = "Dynamic"  # Similar to AWS auto-assign
  }

  tags = {
    Name = "${local.prefix}-appserver-nic"
  }
}

# Associate NSG with Network Interface
# In AWS this is handled automatically by the security group association
resource "azurerm_network_interface_security_group_association" "app_nsg_association" {
  network_interface_id      = azurerm_network_interface.app_server_nic.id
  network_security_group_id = azurerm_network_security_group.appserver_nsg.id
}

# App Server Virtual Machine
# This replaces the aws_instance resource
resource "azurerm_linux_virtual_machine" "app_server" {
  name                = "${local.prefix}-appserver"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  size                = "Standard_D8ps_v5"  # ARM-based VM, equivalent to t4g.2xlarge
  admin_username      = var.app_server_admin_username

  # Network interface attachment
  network_interface_ids = [
    azurerm_network_interface.app_server_nic.id
  ]

  # SSH key configuration
  # Equivalent to key_name in AWS
  admin_ssh_key {
    username   = var.app_server_admin_username
    public_key = tls_private_key.internal_key.public_key_openssh
  }

  # OS Disk Configuration
  # Equivalent to root_block_device in AWS
  os_disk {
    name                 = "${local.prefix}-appserver-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"  # Premium SSD for better performance
    disk_size_gb         = 50  # Same as AWS configuration

    tags = {
      Name = "${local.prefix}-app_server-root-disk"
    }
  }

  # VM Image Configuration
  # Equivalent to AMI in AWS
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-gen2"
    version   = "latest"
  }

  # User data script
  # Same functionality as AWS user_data
  custom_data = base64encode(file("userdata/appserver-init.sh"))

  tags = {
    Name          = "${local.prefix}-appserver-instance"
    ansible_group = "appserver"
  }
}

# Managed Disk for Database
# Equivalent to aws_ebs_volume
resource "azurerm_managed_disk" "db_disk" {
  name                 = "${local.prefix}-db-disk"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  storage_account_type = "Premium_LRS"  # Premium SSD for database performance
  create_option        = "Empty"
  disk_size_gb         = 100  # Same size as AWS EBS volume

  tags = {
    Name = "${local.prefix}-appserver-db-disk"
  }
}

# Attach Data Disk to VM
# Equivalent to aws_volume_attachment
resource "azurerm_virtual_machine_data_disk_attachment" "db_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.db_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.app_server.id
  lun                = "10"  # Logical Unit Number for disk identification
  caching            = "ReadWrite"
}

# Storage Account for Backups
# Equivalent to S3 bucket for backups
resource "azurerm_storage_account" "backup_storage" {
  name                     = replace("${local.prefix}backups", "-", "")  # Storage account names can't have hyphens
  resource_group_name      = module.networking.resource_group_name
  location                = module.networking.resource_group_location
  account_tier            = "Standard"
  account_replication_type = "GRS"  # Geo-redundant storage for backup safety

  tags = {
    Name = "${local.prefix}-backups-storage"
  }
}

# Storage Account for Application Data
# Equivalent to S3 bucket for application data
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

# Storage Containers
# Equivalent to S3 bucket folder/prefix
resource "azurerm_storage_container" "backup_container" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup_storage.name
  container_access_type = "private"  # Private access only
}

resource "azurerm_storage_container" "app_data_container" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.app_data_storage.name
  container_access_type = "private"  # Private access only
}

# Application Gateway Backend Pool Association
# Equivalent to aws_lb_target_group_attachment
resource "azurerm_application_gateway_backend_address_pool_address" "app_server" {
  name                    = "${local.prefix}-app-server"
  backend_address_pool_id = azurerm_application_gateway.app_gateway.backend_address_pool[0].id
  ip_address              = azurerm_network_interface.app_server_nic.private_ip_address
}