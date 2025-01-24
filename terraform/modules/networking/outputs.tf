output "resourcegroup_id" {
  value       = azurerm_resource_group.main.id
  description = "The resource group id of the resource group being created by this module"
}

output "resource_group_location" {
  value = azurerm_resource_group.main.location
  description = "The resource group location of the resource group being created by this module"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
  description = "The resource group name of the resource group being created by this module"
}

output "vpc_id" {
  value       = azurerm_virtual_network.mainvnet.id
  description = "The vpc id of the vpc being created by this module"
}

output "vm_subnet_id" {
  # value       = azurerm_subnet.subnet_with_vm[*].id
  value       = { for zone, subnet in azurerm_subnet.subnet_with_vm : zone => subnet.id }
  description = "the id of the subnet in which VM resides"
}

output "nat_subnet_id" {
  #value       = azurerm_subnet.subnet_with_nat[*].id
  value       = { for zone, subnet in azurerm_subnet.subnet_with_nat : zone => subnet.id }
  description = "the id of the subnet in which NAT Gateway resides"
}

output "vm_subnet" {
  value       = azurerm_subnet.subnet_with_vm
  description = "the VM subnet"
}

output "nat_subnet" {
  value       = azurerm_subnet.subnet_with_nat
  description = "the NAT subnet"
}

