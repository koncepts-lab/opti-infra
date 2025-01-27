# Generate internal SSH key pair
resource "tls_private_key" "internal_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally and ensure proper permissions
resource "local_sensitive_file" "private_key" {
  filename        = pathexpand("~/.ssh/azure-internal-key")
  content         = tls_private_key.internal_key.private_key_pem
  file_permission = "0600"
}



