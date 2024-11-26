# create the app server instance which is a large box with enough compute
# and attach a separate storage for storing RDS items in there
resource "aws_instance" "app_server" {
  ami                    = local.default_ami
  subnet_id              = module.networking.private_subnet_id[0]
  key_name               = aws_key_pair.internal_key_pair.key_name
  availability_zone      = module.networking.private_subnets[0].availability_zone
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  instance_type          = "t4g.2xlarge"

  root_block_device {
    volume_size = 50
    tags = {
      Name = "${local.prefix}-app_server-root-ebs"
    }
    delete_on_termination = true
  }

  tags = {
    Name          = "${local.prefix}-appserver-instance"
    ansible_group = "appserver"
  }

  user_data = file("userdata/appserver-init.sh")
}

resource "aws_ebs_volume" "db_volume" {
  availability_zone = aws_instance.app_server.availability_zone
  size              = 100

  tags = {
    Name = "${local.prefix}-appserver-db-ebs"
  }
}

resource "aws_volume_attachment" "db_volume_attachment" {
  device_name = "/dev/sdh"
  instance_id = aws_instance.app_server.id
  volume_id   = aws_ebs_volume.db_volume.id
}


resource "aws_s3_bucket" "backup_bucket" {
  bucket        = "${local.prefix}-backups"
  force_destroy = false
  tags = {
    Name = "${local.prefix}-backups-bucket"
  }
}

resource "aws_s3_bucket" "app_data" {
  bucket        = "${local.prefix}-app-data"
  force_destroy = true
  tags = {
    Name = "${local.prefix}-app-data-bucket"
  }
}

# add a security group ingress and egress roule on port 443

resource "aws_security_group" "appserver_sg" {
  name        = "appserver_allow_tls"
  description = "Allow HTTPS traffic inbound and all outbound traffic"
  vpc_id      = module.networking.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.prefix}-appserver-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "appserver_allow_inbound_tls" {
  security_group_id = aws_security_group.appserver_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.prefix}-allow-inbound-tls"
  }
}

resource "aws_vpc_security_group_egress_rule" "appserver_outbound_tls" {
  security_group_id = aws_security_group.appserver_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "${local.prefix}-allow-outbound-tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "appserver_internal_all_access" {
  security_group_id            = aws_security_group.appserver_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = data.aws_security_group.default.id
  tags = {
    Name = "${local.prefix}-allow-jumpbox-all-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "appserver_internal_all_comms" {
  security_group_id            = aws_security_group.appserver_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.appserver_sg.id
  tags = {
    Name = "${local.prefix}-allow-internal-all-access"
  }
}

resource "aws_lb_target_group_attachment" "appserver_tga" {
  target_group_arn = aws_lb_target_group.app_server_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}
