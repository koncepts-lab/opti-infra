variable "env" {
  type    = string
  default = "test"
}

variable "profile" {
  type    = string
  default = "oii"
}

variable "product" {
  type    = string
  default = "oii"
}

variable "root_key" {
  type        = string
  description = "key material for the default public key"
}

variable "redundancy" {
  type = number
  description = "The number of AZs to replicate this terraform instance"
  default = 1
}
