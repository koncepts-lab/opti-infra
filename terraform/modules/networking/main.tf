
data "aws_availability_zones" "azs" {
  state = "available"
}

locals {

  base_cidr = "10.0.0.0/16"

  prefix = var.prefix

  num_available_azs = length(data.aws_availability_zones.azs.names) # the total number of azs
  az_count          = min(var.redundancy, local.num_available_azs)  # the number of azs to replicate the infrastructure in
  total_subnets     = 2 * local.az_count                            # the total number of subnets, 1 private and 1 public in each-az
  new_bits          = ceil(log(local.total_subnets, 2))             # calculate the new bits for each az based on the number of total az
}


# create the VPC, the dhcp option
resource "aws_vpc" "mainvpc" {
  cidr_block           = local.base_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_default_vpc_dhcp_options" "default_dopts" {
  tags = {
    Name = "${local.prefix}-dopts"
  }
}

resource "aws_default_route_table" "default_rtb" {
  default_route_table_id = aws_vpc.mainvpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "${local.prefix}-rtb"
  }
}

resource "aws_default_network_acl" "default_nacl" {
  default_network_acl_id = aws_vpc.mainvpc.default_network_acl_id
  tags = {
    Name = "${local.prefix}-nacl"
  }

  subnet_ids = concat(
    sort(aws_subnet.public_subnet[*].id),
    sort(aws_subnet.private_subnet[*].id)
  )

  ingress {
    rule_no    = 1
    from_port  = 0
    to_port    = 0
    protocol   = -1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 2
    from_port  = 0
    to_port    = 0
    protocol   = -1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "${local.prefix}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "self_all_sgr" {
  ip_protocol                  = -1
  security_group_id            = aws_default_security_group.default_sg.id
  referenced_security_group_id = aws_default_security_group.default_sg.id
  description                  = "Self rule for routing traffic within the security group"

  tags = {
    Name = "${local.prefix}-self-all-sgr"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_outside" {
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  security_group_id = aws_default_security_group.default_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Rule for allowing ssh connections from the outside world"

  tags = {
    Name = "${local.prefix}-ext-ssh-sgr"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_traffic_outside" {
  ip_protocol       = -1
  security_group_id = aws_default_security_group.default_sg.id
  description       = "Rule for allowing all traffic to the outside world"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.prefix}-all-ext-sgr"
  }
}


resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "${local.prefix}-ig"
  }
}

# create public subnets
resource "aws_subnet" "public_subnet" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = cidrsubnet(local.base_cidr, local.new_bits, count.index * 2)
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name   = "${local.prefix}-pub-sn-${element(data.aws_availability_zones.azs.names, count.index)}"
    SNType = "public"
  }
}

# create private subnets
resource "aws_subnet" "private_subnet" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = cidrsubnet(local.base_cidr, local.new_bits, count.index * 2 + 1)
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name   = "${local.prefix}-priv-sn-${element(data.aws_availability_zones.azs.names, count.index)}"
    SNType = "private"
  }
}

resource "aws_eip" "nat_ip" {
  count      = local.az_count
  depends_on = [aws_internet_gateway.ig]
  tags = {
    Name = "${local.prefix}-nat-ip-${element(data.aws_availability_zones.azs.names, count.index)}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_internet_gateway.ig]
  count         = local.az_count
  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "${local.prefix}-nat-gw-${element(data.aws_availability_zones.azs.names, count.index)}"
  }
}

resource "aws_route_table_association" "public_rtb_assoc" {
  count          = local.az_count
  route_table_id = aws_default_route_table.default_rtb.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.mainvpc.id
  count  = local.az_count

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${local.prefix}-private-rtb"
  }
}

resource "aws_route_table_association" "private_nat_rtb_association" {
  count          = local.az_count
  route_table_id = aws_route_table.private_rtb[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
