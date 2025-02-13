output "jumpbox_public_ip" {
  value = azurerm_public_ip.jumpbox_ip.ip_address
}

output "app_server_private_ip" {
  value = azurerm_network_interface.app_server_nic.private_ip_address
  description = "Private IP of the app server"
}

# Add key outputs (sensitive)
output "jumpbox_private_key" {
  value     = tls_private_key.jumpbox_key.private_key_pem
  sensitive = true
}

output "app_server_private_key" {
  value     = tls_private_key.app_server_key.private_key_pem
  sensitive = true
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    jumpbox_public_ip     = azurerm_public_ip.jumpbox_ip.ip_address
    app_server_private_ip = azurerm_network_interface.app_server_nic.private_ip_address
    worker_private_ips    = []  # Add worker IPs if you have any
    jumpbox_admin_username = var.jumpbox_admin_username
    app_server_admin_username = var.app_server_admin_username
  })
}


