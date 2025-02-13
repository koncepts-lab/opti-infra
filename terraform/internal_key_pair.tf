# Create an internal key pair that can be used as a method to connect between internal nodes.
# The corresponding private key will also be uploaded to the jumpbox instance so that we
# can access other nodes inside the jumpbox

# Generate the RSA key
resource "tls_private_key" "internal_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the private key locally for SSH access
resource "local_sensitive_file" "private_key" {
  filename        = pathexpand("~/.ssh/oii-internal-key-rsa")
  content         = tls_private_key.internal_key.private_key_openssh
  file_permission = "0600"
}

# Store the private key in ansible directory
resource "local_sensitive_file" "private_key_ansible" {
  filename        = "${path.module}/../playbooks/oii-internal-key-rsa"
  content         = tls_private_key.internal_key.private_key_openssh
  file_permission = "0600"
}

# Store public key in Key Vault for secure access
resource "azurerm_key_vault_secret" "internal_ssh_key" {
  name         = "internal-ssh-private-key"
  value        = tls_private_key.internal_key.private_key_openssh
  key_vault_id = azurerm_key_vault.vault.id  # Reference to your Key Vault

  tags = {
    environment = var.env
    purpose     = "internal-ssh"
  }
}

# Store public key in Key Vault
resource "azurerm_key_vault_secret" "internal_ssh_public_key" {
  name         = "internal-ssh-public-key"
  value        = tls_private_key.internal_key.public_key_openssh
  key_vault_id = azurerm_key_vault.vault.id  # Reference to your Key Vault

  tags = {
    environment = var.env
    purpose     = "internal-ssh"
  }
}

# Output the public key for reference
output "internal_public_key" {
  value     = tls_private_key.internal_key.public_key_openssh
  sensitive = true
}