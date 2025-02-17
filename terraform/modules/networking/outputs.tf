# outputs.tf

# Resource Group outputs - Required in Azure (no AWS equivalent)
# These are necessary as Azure requires resource group management
output "resourcegroup_id" {
  value       = azurerm_resource_group.main.id
  description = "The resource group id of the resource group being created by this module"
}

output "resource_group_location" {
  value       = azurerm_resource_group.main.location
  description = "The resource group location of the resource group being created by this module"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "The resource group name of the resource group being created by this module"
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.subnet_appgw.id
  description = "The ID of the Application Gateway subnet"
}

# Virtual Network ID - Equivalent to AWS VPC ID
# Maintained for consistent network resource referencing across cloud providers
output "vpc_id" {
  value       = azurerm_virtual_network.mainvnet.id
  description = "The virtual network id of the VNet being created by this module"
}

# Subnet IDs - Using map format for Azure's zone-based architecture
# Changed from AWS array format [*].id to Azure map format for better zone mapping
# This change reflects Azure's different availability zone handling (numeric vs named)
output "vm_subnet_id" {
  value = {
    for zone, subnet in azurerm_subnet.subnet_with_vm : zone => subnet.id
  }
  description = "Map of zone to subnet ID where VMs reside (replaces AWS public subnet concept)"
}

output "nat_subnet_id" {
  value = {
    for zone, subnet in azurerm_subnet.subnet_with_nat : zone => subnet.id
  }
  description = "Map of zone to subnet ID where NAT Gateway resides (replaces AWS private subnet concept)"
}

# Complete subnet resources - Maintained for backwards compatibility
# These outputs provide full subnet details including all properties
# Useful for security group associations and network planning
output "vm_subnet" {
  value       = azurerm_subnet.subnet_with_vm
  description = "The complete VM subnet resource (formerly public subnet in AWS)"
}

output "nat_subnet" {
  value       = azurerm_subnet.subnet_with_nat
  description = "The complete NAT subnet resource (formerly private subnet in AWS)"
}

# Note: We maintain this comprehensive output structure because:
# 1. Resource Groups: Azure's fundamental organization unit needs explicit outputs
# 2. Zone Mapping: Azure uses numeric zones (1,2,3) vs AWS's named zones (us-east-1a)
# 3. Subnet Evolution: Changed from public/private to vm/nat terminology while keeping functionality
# 4. Network Security: Azure's NSG model differs from AWS security groups
# 5. Future Compatibility: Structured to support potential multi-cloud deployments
# 
# We specifically avoided removing variables because:
# - It would break existing module references
# - Reduces flexibility for different environment configurations
# - Makes future cloud provider migrations more difficult
# - Removes important context for resource relationships
# - Limits ability to implement different security models per environment