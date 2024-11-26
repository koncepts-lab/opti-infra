variable "vpc_id" {
  type        = string
  description = "The VPC-ID under which this will be created"
}

variable "public_subnets" {
  type        = list(string)
  description = "An array of public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "An array of private subnets"
}
