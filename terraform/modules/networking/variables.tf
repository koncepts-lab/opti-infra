# Core variables
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be created"
}

variable "env" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "prefix" {
  type        = string
  description = "Prefix to be used for resource naming"
}

variable "redundancy" {
  type        = number
  description = "Number of availability zones (1-3)"
  validation {
    condition     = var.redundancy >= 1 && var.redundancy <= 3
    error_message = "Redundancy must be between 1 and 3."
  }
}

# Network configuration
variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "vm_subnet_prefix" {
  type        = string
  description = "Address prefix for VM subnet"
}

variable "nat_subnet_prefix" {
  type        = string
  description = "Address prefix for NAT subnet"
}

# Storage configuration
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

# Application Gateway configuration
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