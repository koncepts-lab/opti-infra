# Public IP for jumpbox - conditionally created
resource "azurerm_public_ip" "jumpbox_ip" {
  count               = var.jumpbox_enable_public_ip ? 1 : 0
  name                = "${local.prefix}-jumpbox-ip"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  allocation_method   = "Static"
  sku                = "Standard"
  
  tags = merge(
    {
      Name = "${local.prefix}-jumpbox-ip"
    },
    var.jumpbox_tags
  )
}

# Network Security Group for jumpbox
resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "${local.prefix}-jumpbox-nsg"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  tags = merge(
    {
      Name = "${local.prefix}-jumpbox-nsg"
    },
    var.jumpbox_tags
  )
}

# Network interface for jumpbox
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

# Jumpbox VM
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${local.prefix}-jumpbox-instance"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  size                = var.jumpbox_size
  
  admin_username      = var.jumpbox_admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.jumpbox_admin_username
    public_key = tls_private_key.internal_key.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  os_disk {
    name                 = "${local.prefix}-jumpbox-root-disk"
    caching              = "ReadWrite"
    storage_account_type = var.jumpbox_os_disk_type
    disk_size_gb         = var.jumpbox_os_disk_size

    tags = merge(
      {
        Name = "${local.prefix}-jumpbox-root-ebs"
      },
      var.jumpbox_tags
    )
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-gen2"
    version   = var.jumpbox_image_version
  }

  plan {
    name      = "8-gen2"
    product   = "rhel"
    publisher = "RedHat"
  }

  custom_data = base64encode(templatefile("${path.module}/userdata/jumpbox-init.sh.tftpl", {
    key_mat = tls_private_key.internal_key.private_key_openssh
  }))

  tags = merge(
    {
      Name           = "${local.prefix}-jumpbox-instance"
      ansible_group  = "bastion"
    },
    var.jumpbox_tags
  )

  depends_on = [
    tls_private_key.internal_key,
    aws_key_pair.root_key,
    aws_key_pair.internal_key_pair
  ]
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}