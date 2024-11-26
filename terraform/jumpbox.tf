resource "aws_instance" "jumpbox" {
  ami                    = local.default_ami
  subnet_id              = module.networking.public_subnet_id[0]
  key_name               = aws_key_pair.root_key.key_name
  availability_zone      = module.networking.public_subnets[0].availability_zone
  vpc_security_group_ids = [data.aws_security_group.default.id]
  instance_type          = "t4g.nano"
  user_data = templatefile("${path.module}/userdata/jumpbox-init.sh.tftpl", {
    key_mat = tls_private_key.internal_key.private_key_openssh
  })

  root_block_device {
    volume_size = 25
    tags = {
      Name = "${local.prefix}-jumpbox-root-ebs"
    }
    delete_on_termination = true
  }

  tags = {
    Name          = "${local.prefix}-jumpbox-instance"
    ansible_group = "bastion"
  }

  depends_on = [tls_private_key.internal_key, aws_key_pair.root_key, aws_key_pair.internal_key_pair]
}
