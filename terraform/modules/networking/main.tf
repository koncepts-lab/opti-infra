locals {
  base_cidr = "10.0.0.0/16"
  new_bits = 8
  prefix = var.prefix
  availability_zones = ["1", "2", "3"]
  az_count              = length(local.availability_zones)
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "main-resources"
  location = "East US"

  tags = {
    terraform = "true"
    env       = "${local.prefix}-rg"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "mainvnet" {
  name                = "main-network"
  address_space       = [local.base_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    terraform = "true"
    env       = "${local.prefix}-vpc"
  }
}

# Create a subnet
resource "azurerm_subnet" "subnet_with_vm" {
  for_each               = toset(local.availability_zones)
  name                   = "${local.prefix}-internal-sn-${each.value}"
  # name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes       = [cidrsubnet(local.base_cidr, local.new_bits, each.key)]
  # address_prefixes     = [cidrsubnet(local.base_cidr, 8, 1)]
  service_endpoints = ["Microsoft.Storage"]
}

# Create another subnet
resource "azurerm_subnet" "subnet_with_nat" {
  for_each               = toset(local.availability_zones)
  name                   = "${local.prefix}-internal-nat-sn-${each.value}"
  #name                 = "internal-with-nat"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes       = [cidrsubnet(local.base_cidr, local.new_bits, each.key+3)]
  # address_prefixes     = [cidrsubnet(local.base_cidr, 8,2)] 
  service_endpoints = ["Microsoft.Storage"]
}

# Create NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  for_each               = toset(local.availability_zones)
  # name                    = "main-nat-gateway"
   name                   = "${local.prefix}-nat-gateway-${each.value}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  sku_name               = "Standard"

  tags = {
    terraform = "true"
    env       = "${local.prefix}-nat-gw"
  }
}

# Create a public IP for NAT Gateway
resource "azurerm_public_ip" "nat_ip" {
  for_each               = toset(local.availability_zones)
  name                   = "${local.prefix}-nat-ip-${each.value}"
  # name                = "nat-gateway-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    terraform = "true"
    env       = "${local.prefix}-nat-ip"
  }
}

# Associate the public IP with the NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  for_each               = toset(local.availability_zones)
  nat_gateway_id         = azurerm_nat_gateway.nat_gateway[each.value].id
  public_ip_address_id   = azurerm_public_ip.nat_ip[each.value].id
  # nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  # public_ip_address_id = azurerm_public_ip.nat_ip.id
}

# Associate the NAT Gateway with the subnet
resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
   for_each               = toset(local.availability_zones)
   subnet_id              = azurerm_subnet.subnet_with_nat[each.value].id
  nat_gateway_id         = azurerm_nat_gateway.nat_gateway[each.value].id
  # subnet_id      = azurerm_subnet.subnet_with_nat.id
  # subnet_id = azurerm_subnet.subnet_with_nat["1"].id
  # nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}