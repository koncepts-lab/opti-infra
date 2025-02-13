locals {
  base_cidr = "10.0.0.0/16"
  prefix    = var.prefix
  
  # Calculate zones based on redundancy
  az_count          = var.redundancy
  availability_zones = slice(["1", "2", "3"], 0, var.redundancy)
  
  # Calculate subnet bits
  total_subnets     = 2 * local.az_count  # VM and NAT subnet per zone
  new_bits          = ceil(log(local.total_subnets, 2))
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

# Create VM subnets
resource "azurerm_subnet" "subnet_with_vm" {
  for_each             = toset(local.availability_zones)
  name                 = "${var.prefix}-${var.env}-vm-sn-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = [cidrsubnet(local.base_cidr, local.new_bits, parseint(each.key, 10))]
  service_endpoints    = ["Microsoft.Storage"]
}

# Create NAT subnets
resource "azurerm_subnet" "subnet_with_nat" {
  for_each             = toset(local.availability_zones)
  name                 = "${var.prefix}-${var.env}-nat-sn-${each.value}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = [cidrsubnet(local.base_cidr, local.new_bits, parseint(each.key, 10) + local.az_count)]
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