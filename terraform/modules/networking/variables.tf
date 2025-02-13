variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where networking resources will be created"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be created"
}

variable "env" {
  type        = string
  description = "Environment name (dev, test, prod) for resource naming and tagging"
  default     = "test"
}

variable "prefix" {
  type        = string
  description = "Prefix to be used for resource naming"
  default     = "oii-test"
}

variable "redundancy" {
  type        = number
  description = "Number of availability zones to use (1-3). Controls the redundancy of resources"
  default     = 1
  validation {
    condition     = var.redundancy >= 1 && var.redundancy <= 3
    error_message = "Redundancy value must be between 1 and 3."
  }
}