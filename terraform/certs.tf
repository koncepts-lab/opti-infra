# Create a DNS Zone 
resource "azurerm_dns_zone" "oi_portal" {
  name                = "oi-portal.com"
  resource_group_name = module.networking.resource_group_name

tags = {
    terraform = "true"
    env       = "${local.prefix}-dns-zn"
  }
}

# Declare the azurerm_client_config data source to fetch client information
data "azurerm_client_config" "example" {}

# Create a Key Vault to store the certificate
resource "azurerm_key_vault" "main" {
  name                        = "oii-keyvault"
  location                    = module.networking.resource_group_location
  resource_group_name         = module.networking.resource_group_name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.example.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  tags = {
    terraform = "true"
    env       = "${local.prefix}-ky-vt"
  }
}

# Request an SSL certificate
resource "azurerm_key_vault_certificate" "oi_portal_cert" {
  name         = "oi-portal-cert"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"  
    }

    secret_properties {
      content_type = "application/x-pkcs12" 
    }

    key_properties {
      exportable = true  
      key_type   = "RSA"  
      key_size   = 2048   
      reuse_key  = true   
    }

    x509_certificate_properties {
      subject             = "CN=oi-portal.com" 
      key_usage           = ["digitalSignature", "keyEncipherment"]  
      validity_in_months = 12  

      subject_alternative_names {
        dns_names = [
            "oi-portal.com",
            "*.oi-portal.com"
        ]
      }
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"  
      }
      trigger {
        days_before_expiry = 30        
      }
    }
  }

  tags = {
    terraform = "true"
    env       = "${local.prefix}-cert"
  }
}



# Create a DNS record for certificate validation
resource "azurerm_dns_cname_record" "validation" {
  name                = "example-validation-name"  
  zone_name           = azurerm_dns_zone.oi_portal.name
  resource_group_name = module.networking.resource_group_name
  ttl                 = 300
  record              = "example-validation-record-value"  
}

# Use the certificate in App Service (once validation is complete)
# resource "azurerm_app_service_certificate" "oi_portal_cert" {
 # name                = "oi-portal-cert"
 # resource_group_name = azurerm_resource_group.main.name
  #key_vault_secret_id = azurerm_key_vault_certificate.oi_portal_cert.secret_id
 # location                = azurerm_resource_group.main.location
 # tags = {
 #   environment = "production"
 # }
#}