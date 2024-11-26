resource "aws_db_subnet_group" "db_sng" {
  name        = "${var.prefix}-default-db-subnet-grp"
  subnet_ids  = var.private_subnet_id
  description = "A subnet group of all the private subnets for db instances"

  tags = {
    Name = "${var.prefix}-db-sng"
  }
}

data "aws_security_group" "default_sg" {
  name   = "default"
  vpc_id = var.vpc_id
}

data "aws_vpc" "default_vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "db_sg" {
  name   = "${var.prefix}-app-db-sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.prefix}-app-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_sgr_internal_ingress" {
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.db_sg.id
  security_group_id            = aws_security_group.db_sg.id
  tags = {
    Name = "${var.prefix}-app-db-internal-ingress-sgr"
  }
}

resource "aws_vpc_security_group_egress_rule" "db_sgr_internal_egress" {
  ip_protocol       = -1
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = data.aws_vpc.default_vpc.cidr_block
  description       = "Allows egress to any place in our VPC"
  tags = {
    Name = "${var.prefix}-app-db-internal-egress-sgr"
  }
}

resource "aws_vpc_security_group_ingress_rule" "default_to_db" {
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = data.aws_security_group.default_sg.id
  description                  = "Allow connections to 3306 from the default security group"
  tags = {
    Name = "${var.prefix}-default-to-db"
  }
}

data "aws_secretsmanager_secret" "db_master_password" {
  name       = "${var.prefix}-db-master-password"
  depends_on = [aws_secretsmanager_secret.db_master_password]
}

data "aws_secretsmanager_secret_version" "password" {
  secret_id  = data.aws_secretsmanager_secret.db_master_password.id
  depends_on = [aws_secretsmanager_secret_version.db_master_pwd_secret]
}

resource "aws_db_instance" "app_db" {
  db_subnet_group_name   = aws_db_subnet_group.db_sng.name
  instance_class         = "db.t3.micro"
  engine                 = "mariadb"
  engine_version         = "10.6.14"
  username               = var.db_username
  password               = data.aws_secretsmanager_secret_version.password.secret_string
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  allocated_storage      = 30
  skip_final_snapshot    = true
  tags = {
    Name = "${var.prefix}-app_db"
  }
}
