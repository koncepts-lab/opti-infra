# Create Storage Account for logs (equivalent to S3 bucket)
resource "azurerm_storage_account" "logs" {
  name                     = replace("${local.prefix}logs", "-", "")  # Storage account name can't have hyphens
  resource_group_name      = module.networking.resource_group_name
  location                = module.networking.resource_group_location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name = "${local.prefix}-logs-storage"
  }
}

# Create container for logs (equivalent to S3 bucket folder)
resource "azurerm_storage_container" "logs" {
  name                  = "applogs"
  storage_account_name  = azurerm_storage_account.logs.name
  container_access_type = "private"
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "agw" {
  name                = "${local.prefix}-agw-ip"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${local.prefix}-agw-ip"
  }
}

# Application Gateway (equivalent to ALB)
resource "azurerm_application_gateway" "app_gateway" {
  name                = "${local.prefix}-app-gateway"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway_identity.id]
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = module.networking.appgw_subnet_id 
  }

  backend_address_pool {
  name = "${local.prefix}-backend-pool"
  ip_addresses = [azurerm_network_interface.app_server_nic.private_ip_address]
}

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  # SSL Certificate from Key Vault
  ssl_certificate {
    name                = "app-gateway-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.app_gateway_cert.secret_id
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol             = "Http"
    request_timeout      = 60
    path                 = "/"
    probe_name           = "health-probe"
  }

  probe {
    name                = "health-probe"
    host                = "127.0.0.1"
    interval            = 60
    timeout             = 5
    path                = "/"
    unhealthy_threshold = 3
    protocol            = "Http"
    match {
      status_code = ["200"]
    }
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name            = "https-port"
    protocol                      = "Https"
    ssl_certificate_name          = "app-gateway-cert"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name            = "http-port"
    protocol                      = "Http"
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-to-https-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    redirect_configuration_name = "http-to-https"
    priority                   = 2
  }

  request_routing_rule {
    name                       = "https-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "${local.prefix}-backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 1
  }

  # Enable logging
  

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"  # Or a more recent policy
  }

  waf_configuration {
    enabled                  = true
    firewall_mode           = "Prevention"
    rule_set_type          = "OWASP"
    rule_set_version       = "3.2"
    file_upload_limit_mb   = 100
    max_request_body_size_kb = 128
  }

  tags = {
    Name = "${local.prefix}-app-gateway"
  }

  depends_on = [
    azurerm_linux_virtual_machine.app_server,
    azurerm_storage_account.logs
  ]
}

resource "azurerm_monitor_diagnostic_setting" "app_gateway_diag" {
  name                = "${local.prefix}-app-gateway-logs"
  target_resource_id  = azurerm_application_gateway.app_gateway.id
  storage_account_id  = azurerm_storage_account.logs.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# DNS Record (similar to Route53)
resource "azurerm_dns_cname_record" "app" {
  name                = "app"
  zone_name           = azurerm_dns_zone.oi_portal.name
  resource_group_name = module.networking.resource_group_name
  ttl                = 60
  record             = azurerm_public_ip.agw.ip_address  # Use IP address instead of FQDN
}

resource "azurerm_user_assigned_identity" "app_gateway_identity" {
  name                = "${local.prefix}-app-gateway-identity"
  resource_group_name = module.networking.resource_group_name
  location            = module.networking.resource_group_location

  tags = {
    Name = "${local.prefix}-app-gateway-identity"
  }
}



