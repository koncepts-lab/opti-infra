# create an internal key pair that can be used as a method to connect between internal nodes.
# the corresponding private key will also be uploaded to the jumpbox instance so that we
# can access other nodes inside the jumpbox

resource "tls_private_key" "internal_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "internal_key_pair" {
  key_name   = "internal_key"
  public_key = tls_private_key.internal_key.public_key_openssh
}

resource "local_sensitive_file" "public_key" {
  filename        = pathexpand("~/.ssh/oii-internal-key-rsa")
  content         = tls_private_key.internal_key.private_key_openssh
  file_permission = 0600
}

resource "local_sensitive_file" "public_key_ansible" {
  filename        = "${path.module}/../playbooks/oii-nternal-key-rsa"
  content         = tls_private_key.internal_key.private_key_openssh
  file_permission = 0600
}
