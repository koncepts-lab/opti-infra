#output "private_key" {
#  value     = tls_private_key.root_key.private_key_pem
#  sensitive = true
#}

output "jumpbox_public_ip" {
  value = azurerm_public_ip.jumpbox_ip.ip_address
}


