# Public IP for jumpbox
resource "azurerm_public_ip" "jumpbox_ip" {
  name                = "jumpbox-ip"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  allocation_method   = "Static"
  sku                = "Standard"
}

# Network Security Group for jumpbox
resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "jumpbox-nsg"
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
}

# Network interface for jumpbox
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "jumpbox-nic"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name

  ip_configuration {
    name                          = "jumpbox-ipconfig"
    subnet_id                     = module.networking.vm_subnet_id["1"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_ip.id
  }
}

# Jumpbox VM
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "jumpbox-vm"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  size                = "Standard_B1s"  
  admin_username      = var.jumpbox_admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = "jumpboxadmin"
    public_key = tls_private_key.internal_key.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}
