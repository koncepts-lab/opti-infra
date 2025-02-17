# Authentication and Core Settings
variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID"
}

variable "product" {
  type        = string
  description = "Product name for resource naming"
}

variable "env" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource naming"
}

# Network Configuration
variable "redundancy" {
  type        = number
  description = "Number of availability zones (1-3)"
  default     = 2
  validation {
    condition     = var.redundancy >= 1 && var.redundancy <= 3
    error_message = "Redundancy must be between 1 and 3."
  }
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default =["10.0.0.0/16"]
}

variable "vm_subnet_prefix" {
  type        = string
  description = "Subnet prefix for VM subnet"
  default     = "10.0.1.0/24"
}

variable "nat_subnet_prefix" {
  type        = string
  description = "Subnet prefix for NAT subnet"
  default     = "10.0.2.0/24"
}

variable "appgw_subnet_prefix" {
  type        = string
  description = "Subnet prefix for Application Gateway subnet"
  default     = "10.0.3.0/24"
}

# Jumpbox Configuration
variable "jumpbox_size" {
  type        = string
  description = "The size of the jumpbox VM"
  default     = "Standard_B1s"
}

variable "jumpbox_admin_username" {
  type        = string
  description = "The admin username for the jumpbox"
}

variable "jumpbox_ssh_key" {
  type        = string
  description = "SSH public key for jumpbox access"
}

variable "jumpbox_os_disk_size" {
  type        = number
  description = "The size of the jumpbox OS disk in GB"
  default     = 64
}

variable "jumpbox_os_disk_type" {
  type        = string
  description = "The type of OS disk (e.g., Standard_LRS, Premium_LRS)"
  default     = "Standard_LRS"
}

variable "jumpbox_image_version" {
  type        = string
  description = "The version of the RHEL image to use"
  default     = "latest"
}

variable "jumpbox_enable_public_ip" {
  type        = bool
  description = "Whether to enable public IP for jumpbox"
  default     = true
}

variable "jumpbox_subnet_zone" {
  type        = string
  description = "The availability zone for the jumpbox subnet"
  default     = "1"
}

variable "jumpbox_tags" {
  type        = map(string)
  description = "Additional tags for the jumpbox resources"
  default     = {}
}

# App Server Configuration
variable "app_server_size" {
  type        = string
  description = "Size of the app server VM"
  default     = "Standard_D8ps_v5"
}

variable "app_server_admin_username" {
  type        = string
  description = "Admin username for app server"
}

variable "app_server_ssh_key" {
  type        = string
  description = "SSH public key for app server access"
}

variable "app_server_os_disk_size" {
  type        = number
  description = "Size of the app server OS disk in GB"
  default     = 64
}

variable "app_server_data_disk_size" {
  type        = number
  description = "Size of the app server data disk in GB"
  default     = 100
}

# Application Gateway Configuration
variable "app_gateway_sku_name" {
  type        = string
  description = "SKU name for Application Gateway"
  default     = "Standard_v2"
}

variable "app_gateway_sku_tier" {
  type        = string
  description = "SKU tier for Application Gateway"
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  type        = number
  description = "Capacity units for Application Gateway"
  default     = 2
}

# Storage Configuration
variable "storage_account_tier" {
  type        = string
  description = "Tier for storage accounts (Standard or Premium)"
  default     = "Standard"
}

variable "backup_replication_type" {
  type        = string
  description = "Replication type for backup storage (LRS, GRS, etc.)"
  default     = "LRS"
}

variable "appdata_replication_type" {
  type        = string
  description = "Replication type for app data storage (LRS, GRS, etc.)"
  default     = "LRS"
}

# Key Vault Configuration
variable "key_vault_object_id" {
  type        = string
  description = "Object ID for Key Vault access"
}

# DNS Configuration
variable "domain_name" {
  type        = string
  description = "The domain name for DNS configuration"
  default     = "oi-portal.com"
}

# Certificate Configuration
variable "certificate_subject" {
  type        = string
  description = "Subject for SSL certificate"
  default     = "CN=oi-portal.com"
}

variable "certificate_validity_months" {
  type        = number
  description = "Validity period for certificates in months"
  default     = 12
}

variable "backup_storage_access_key" {
  type        = string
  description = "Access key for backup storage account"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Environment name (alias for env)"
}

variable "app_data_storage_access_key" {
  type        = string
  description = "Access key for application data storage account"
  sensitive   = true
}

variable "email_username" {
  type        = string
  description = "Username for email service"
}

variable "email_password" {
  type        = string
  description = "Password for email service"
  sensitive   = true
}

variable "create_state_storage" {
  type        = bool
  description = "Whether to create storage account for Terraform state"
  default     = false
}