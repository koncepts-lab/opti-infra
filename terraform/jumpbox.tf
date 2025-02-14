# =============================================================================
# Jumpbox (Bastion Host) Configuration
# Purpose: Creates a secure entry point for infrastructure access
# =============================================================================

# -----------------------------------------------------------------------------
# Public IP Configuration
# Creates a public IP address for the jumpbox if enabled
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "jumpbox_ip" {
  count               = var.jumpbox_enable_public_ip ? 1 : 0
  name                = "${local.prefix}-jumpbox-ip"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  allocation_method   = "Static"  # Required for reliable remote access
  sku                = "Standard" # Required for availability zone support
 
  tags = merge(
    {
      Name = "${local.prefix}-jumpbox-ip"
    },
    var.jumpbox_tags
  )
}

# -----------------------------------------------------------------------------
# Network Security Group
# Defines inbound and outbound security rules for the jumpbox
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "${local.prefix}-jumpbox-nsg"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  # Allow SSH inbound access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"  # Consider restricting to specific IP ranges
    destination_address_prefix = "*"
  }

  tags = merge(
    {
      Name = "${local.prefix}-jumpbox-nsg"
    },
    var.jumpbox_tags
  )
}

# -----------------------------------------------------------------------------
# Network Interface
# Creates the primary network interface for the jumpbox
# -----------------------------------------------------------------------------
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "${local.prefix}-jumpbox-nic"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  ip_configuration {
    name                          = "jumpbox-ipconfig"
    subnet_id                     = module.networking.vm_subnet_id[var.jumpbox_subnet_zone]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.jumpbox_enable_public_ip ? azurerm_public_ip.jumpbox_ip[0].id : null
  }

  tags = merge(
    {
      Name = "${local.prefix}-jumpbox-nic"
    },
    var.jumpbox_tags
  )
}

# -----------------------------------------------------------------------------
# Network Security Group Association
# Links the NSG to the network interface
# -----------------------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}

# -----------------------------------------------------------------------------
# Virtual Machine
# Creates the jumpbox VM with both internal and external SSH key access
# -----------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${local.prefix}-jumpbox-instance"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  size                = var.jumpbox_size
 
  admin_username      = var.jumpbox_admin_username
  disable_password_authentication = true

  # Configure both provided (external) and internal SSH keys
  dynamic "admin_ssh_key" {
    for_each = [
      {
        username   = var.jumpbox_admin_username
        public_key = var.jumpbox_ssh_key  # External key for CI/CD access
      },
      {
        username   = var.jumpbox_admin_username
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
    azurerm_network_interface.jumpbox_nic.id
  ]

  # OS disk configuration
  os_disk {
    name                 = "${local.prefix}-jumpbox-root-disk"
    caching              = "ReadWrite"
    storage_account_type = var.jumpbox_os_disk_type
    disk_size_gb         = var.jumpbox_os_disk_size
  }

  # OS image configuration - RedHat Enterprise Linux
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-gen2"  # RHEL 8
    version   = var.jumpbox_image_version
  }

  # Required for RHEL plan
  plan {
    name      = "8-gen2"
    product   = "rhel"
    publisher = "RedHat"
  }

  # Initialize the jumpbox with required software and configuration
  custom_data = base64encode(templatefile("${path.module}/userdata/jumpbox-init.sh.tftpl", {
    key_mat = tls_private_key.internal_key.private_key_openssh
    jumpbox_admin_username = var.jumpbox_admin_username
  }))

  # Resource tags
  tags = {
    Name           = "${local.prefix}-jumpbox-instance"
    ansible_group  = "bastion"
  }

  depends_on = [
    tls_private_key.internal_key,
  ]
}



