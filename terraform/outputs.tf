output "jumpbox_public_ip" {
  value       = var.jumpbox_enable_public_ip ? azurerm_public_ip.jumpbox_ip[0].ip_address : null
  description = "Public IP address of the jumpbox (if enabled)"
  sensitive   = true
}

output "app_server_private_ip" {
  value = azurerm_network_interface.app_server_nic.private_ip_address
  description = "Private IP of the app server"
}

# Add key outputs (sensitive)
output "jumpbox_private_ip" {
  value       = azurerm_network_interface.jumpbox_nic.private_ip_address
  description = "Private IP address of the jumpbox"
}

# Application Gateway subnet output
output "appgw_subnet_id" {
  value       = module.networking.appgw_subnet_id
  description = "The ID of the Application Gateway Subnet"
}

output "appgw_subnet" {
  value       = module.networking.appgw_subnet
  description = "The Application Gateway Subnet"
}


resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    jumpbox_public_ip         = var.jumpbox_enable_public_ip ? azurerm_public_ip.jumpbox_ip[0].ip_address : null
    app_server_private_ip     = azurerm_network_interface.app_server_nic.private_ip_address
    worker_private_ips        = []
    jumpbox_admin_username    = var.jumpbox_admin_username
    app_server_admin_username = var.app_server_admin_username
  })
}

output "internal_ssh_key" {
  value       = tls_private_key.internal_key.private_key_openssh
  sensitive   = true
  description = "Internal SSH key for infrastructure access"
}

output "backup_storage_name" {
  value       = azurerm_storage_account.backup_storage.name
  description = "Name of the backup storage account"
}

output "application_gateway_ip" {
  value       = azurerm_public_ip.agw.ip_address
  description = "Public IP address of the Application Gateway"
}

