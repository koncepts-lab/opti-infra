locals {
  base_cidr = "10.0.0.0/16"
  prefix    = var.prefix
  
  # Calculate zones based on redundancy
  az_count          = var.redundancy
  availability_zones = slice(["1", "2", "3"], 0, var.redundancy)
  
  # Calculate subnet bits
  total_subnets     = 2 * local.az_count  # VM and NAT subnet per zone
  new_bits          = ceil(log(2 * local.total_subnets, 2))
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    terraform = "true"
    env      = var.env
    prefix   = var.prefix
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "mainvnet" {
  name                = "${var.prefix}-${var.env}-network"
  address_space       = [local.base_cidr]
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    terraform = "true"
    env      = var.env
  }
}

# VM subnets
resource "azurerm_subnet" "subnet_with_vm" {
  for_each             = toset(local.availability_zones)
  name                 = "${var.prefix}-${var.env}-vm-sn-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = [cidrsubnet(local.base_cidr, local.new_bits, 2 * (parseint(each.value, 10) - 1))]
  service_endpoints    = ["Microsoft.Storage"]
}

# NAT subnets
resource "azurerm_subnet" "subnet_with_nat" {
  for_each             = toset(local.availability_zones)
  name                 = "${var.prefix}-${var.env}-nat-sn-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = [cidrsubnet(local.base_cidr, local.new_bits, 2 * (parseint(each.value, 10) - 1) + 1)]
  service_endpoints    = ["Microsoft.Storage"]
}

# Create NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  for_each            = toset(local.availability_zones)
  name                = "${var.prefix}-${var.env}-nat-gw-${each.value}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
  tags = {
    terraform = "true"
    env      = var.env
  }
}

# Create public IPs for NAT Gateway
resource "azurerm_public_ip" "nat_ip" {
  for_each            = toset(local.availability_zones)
  name                = "${var.prefix}-${var.env}-nat-ip-${each.value}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    terraform = "true"
    env      = var.env
  }
}

# Associate public IPs with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  for_each            = toset(local.availability_zones)
  nat_gateway_id      = azurerm_nat_gateway.nat_gateway[each.value].id
  public_ip_address_id = azurerm_public_ip.nat_ip[each.value].id
  # nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  # public_ip_address_id = azurerm_public_ip.nat_ip.id
}

# Associate NAT Gateway with subnet
resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
  for_each       = toset(local.availability_zones)
  subnet_id      = azurerm_subnet.subnet_with_nat[each.value].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[each.value].id
  # subnet_id      = azurerm_subnet.subnet_with_nat.id
  # subnet_id = azurerm_subnet.subnet_with_nat["1"].id
  # nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# VNet-level Network Security Group
resource "azurerm_network_security_group" "vnet_nsg" {
  name                = "${var.prefix}-${var.env}-vnet-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS inbound
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP inbound (for redirection to HTTPS)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH only from specific IPs (you should restrict this)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"  # Should be restricted to your IP range
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  tags = {
    terraform = "true"
    env      = var.env
  }
}

# Subnet-specific NSGs
resource "azurerm_network_security_group" "vm_subnet_nsg" {
  for_each            = toset(local.availability_zones)
  name                = "${var.prefix}-${var.env}-vm-subnet-nsg-${each.value}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow inbound from App Gateway
  security_rule {
    name                       = "AllowAppGatewayInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Allow internal communication
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    terraform = "true"
    env      = var.env
  }
}

# NSG for private subnets (NAT subnets)
resource "azurerm_network_security_group" "nat_subnet_nsg" {
  for_each            = toset(local.availability_zones)
  name                = "${var.prefix}-${var.env}-nat-subnet-nsg-${each.value}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow internal communication only
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range         = "*"
    destination_port_range    = "*"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  tags = {
    terraform = "true"
    env      = var.env
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg_assoc" {
  for_each                  = toset(local.availability_zones)
  subnet_id                 = azurerm_subnet.subnet_with_vm[each.value].id
  network_security_group_id = azurerm_network_security_group.vm_subnet_nsg[each.value].id
}

resource "azurerm_subnet_network_security_group_association" "nat_subnet_nsg_assoc" {
  for_each                  = toset(local.availability_zones)
  subnet_id                 = azurerm_subnet.subnet_with_nat[each.value].id
  network_security_group_id = azurerm_network_security_group.nat_subnet_nsg[each.value].id
}