# Create public IP for Load Balancer
resource "azurerm_public_ip" "lb_ip" {
  name                = "lb-public-ip"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  allocation_method   = "Static"
  sku                = "Standard" 

  tags = {
    terraform = "true"
    env       = "${local.prefix}-lb-ip"
  } 
}

# Create Load Balancer
resource "azurerm_lb" "main_lb" {
  name                = "main-load-balancer"
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  sku                = "Standard"  

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }

    tags = {
    terraform = "true"
    env       = "${local.prefix}-lb"
  }
}

# Create Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main_pool" {
  name            = "main-backend-pool"
  loadbalancer_id = azurerm_lb.main_lb.id
}

# Create Health Probe
resource "azurerm_lb_probe" "main_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.main_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Create Load Balancing Rule
resource "azurerm_lb_rule" "main_rule" {
  name                          = "http-rule"
  loadbalancer_id               = azurerm_lb.main_lb.id
  probe_id                      = azurerm_lb_probe.main_probe.id
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.main_pool.id]
  frontend_ip_configuration_name = "frontend-ip"
  protocol                      = "Tcp"
  frontend_port                 = 80
  backend_port                  = 80
}

# Associate NIC with Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "main_pool_assoc" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main_pool.id
}

# Create Storage Account
resource "azurerm_storage_account" "lb_logs" {
  name                     = "lblogstorage${random_string.unique.result}"
  resource_group_name      = module.networking.resource_group_name
  location                 = module.networking.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    terraform = "true"
    env       = "${local.prefix}-lb-lg-sa"
  }
}

# Create random string for unique storage account name
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# Create Container for logs
resource "azurerm_storage_container" "lb_logs" {
  name                  = "lb-logs"
  storage_account_name  = azurerm_storage_account.lb_logs.name
  container_access_type = "private"
}

# Enable diagnostic settings for Load Balancer
resource "azurerm_monitor_diagnostic_setting" "lb_diagnostics" {
  name                = "lb-diagnostics"
  target_resource_id  = azurerm_lb.main_lb.id
  storage_account_id  = azurerm_storage_account.lb_logs.id

  log {
    category_group = "allLogs"
    enabled       = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}