# In AWS, we used Route53 for DNS and ACM for certificates
# In Azure, we use Azure DNS and Key Vault for certificates

# Create/Import DNS Zone
# AWS: aws_route53_zone
# Azure: azurerm_dns_zone
resource "azurerm_dns_zone" "oi_portal" {
  name                = "oi-portal.com"
  resource_group_name = module.networking.resource_group_name

  tags = {
    Name = "${local.prefix}-dns-zone"
  }
}

# Import existing DNS zone
# AWS: Used Route53 zone ID directly
# Azure: Uses full resource path including subscription and resource group
import {
  to = azurerm_dns_zone.oi_portal
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${module.networking.resource_group_name}/providers/Microsoft.Network/dnszones/oi-portal.com"
}

# Generate SSL Certificate
# AWS: Used ACM (aws_acm_certificate)
# Azure: Uses Key Vault Certificate with more detailed configuration
resource "azurerm_key_vault_certificate" "oi_portal_cert" {
  name         = "${local.prefix}-oi-portal-cert"
  key_vault_id = azurerm_key_vault.vault.id

  certificate_policy {
    # Issuer configuration - Self-signed in this case
    # In AWS, this was handled automatically by ACM
    issuer_parameters {
      name = "Self"
    }

    # Key configuration - Not explicitly required in AWS ACM
    key_properties {
      exportable = true      # Allow export of the certificate
      key_size   = 2048      # Standard RSA key size
      key_type   = "RSA"     # Using RSA encryption
      reuse_key  = true      # Reuse key on renewal
    }

    # Auto-renewal configuration - AWS ACM handled this automatically
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30  # Start renewal process 30 days before expiry
      }
    }

    # Certificate content type
    secret_properties {
      content_type = "application/x-pkcs12"  # Standard format for certificates
    }

    # Certificate properties
    # AWS ACM simplified this, but Azure needs explicit configuration
    x509_certificate_properties {
      # Extended Key Usage for server authentication
      # 1.3.6.1.5.5.7.3.1 = Server Authentication
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      # Define how the certificate can be used
      key_usage = [
        "digitalSignature",
        "keyEncipherment"
      ]

      subject            = "CN=oi-portal.com"
      validity_in_months = 12  # 1 year validity

      # Same as AWS subject_alternative_names
      subject_alternative_names {
        dns_names = ["oi-portal.com", "*.oi-portal.com"]
      }
    }
  }

  tags = {
    Name = "${local.prefix}-oi-portal-cert"
  }
}

# DNS Validation Record
# AWS: Used aws_route53_record with values from ACM
# Azure: Uses TXT record with Key Vault certificate name
resource "azurerm_dns_txt_record" "cert_validation" {
  name                = "@"
  zone_name           = azurerm_dns_zone.oi_portal.name
  resource_group_name = module.networking.resource_group_name
  ttl                 = 300  # Same as AWS configuration

  record {
    # Azure format for certificate validation
    value = "MS=ms${azurerm_key_vault_certificate.oi_portal_cert.name}"
  }

  tags = {
    Name = "${local.prefix}-cert-validation"
  }
}

# Application Gateway Certificate
# This is Azure-specific as we need a separate certificate for Application Gateway
# In AWS, we could use the same ACM certificate for ALB
resource "azurerm_key_vault_certificate" "app_gateway_cert" {
  name         = "${local.prefix}-app-gateway-cert"
  key_vault_id = azurerm_key_vault.vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      key_usage = [
        "digitalSignature",
        "keyEncipherment"
      ]
      subject            = "CN=*.oi-portal.com"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = ["*.oi-portal.com"]
      }
    }
  }

  tags = {
    Name = "${local.prefix}-app-gateway-cert"
  }
}

# Outputs
# Additional outputs needed for Azure integration
output "certificate_thumbprint" {
  value = azurerm_key_vault_certificate.oi_portal_cert.thumbprint
}

output "dns_zone_nameservers" {
  value = azurerm_dns_zone.oi_portal.name_servers
}