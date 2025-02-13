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

variable "redundancy" {
  type        = number
  description = "Number of availability zones (1-3)"
  default     = 2
  validation {
    condition     = var.redundancy >= 1 && var.redundancy <= 3
    error_message = "Redundancy must be between 1 and 3."
  }
}

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
  default     = 25
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