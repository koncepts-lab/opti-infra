terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~>5.0"
    }
    tls = {
      source = "hashicorp/tls",
      version = "~>4.0.5"
    }
    
    local = {
      source = "hashicorp/local",
      version = "~>2.5.1"
    }
  }
}

provider "aws" {
  profile = var.profile

  default_tags {
    tags = {
      terraform = "true"
      env       = "${var.product}-${var.env}"
    }
  }
}

module "networking" {
  source     = "./modules/networking"
  env        = "${var.product}-${var.env}"
  prefix     = "${var.product}-${var.env}"
  redundancy = var.redundancy
}

locals {
  prefix      = "${var.product}-${var.env}"
  default_ami = "ami-01c3c55948a949a52"
}

resource "aws_key_pair" "root_key" {
  key_name   = "root_key"
  public_key = var.root_key

  tags = {
    Name = "${local.prefix}-root_key"
  }
}

data "aws_security_group" "default" {
  name       = "default"
  depends_on = [module.networking]
}
