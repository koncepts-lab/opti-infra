variable "env" {
  type    = string
  default = "test"
}

variable "product" {
  type    = string
  default = "oii"
}

variable "app_server_admin_username" {
  description = "Admin username for the app server VM"
  type        = string
}

variable "jumpbox_admin_username" {
  description = "Admin username for the jumpbox VM"
  type        = string
}
