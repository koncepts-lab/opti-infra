output "jumpbox_public_dns" {
  value       = aws_instance.jumpbox.public_dns
  description = "The public dns of the jumpbox machine"
}

output "appserver_public_dns" {
  value         = aws_instance.app_server.private_dns
  description = "The public dns of the appserver machine"
}

resource "local_file" "inventory_ini" {
  filename = "${path.module}/../playbooks/inventory.ini"
    content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
        jumpbox_dns = aws_instance.jumpbox.public_dns
        app_server_dns = aws_instance.app_server.private_dns
        workers_dns = []
        })

}
