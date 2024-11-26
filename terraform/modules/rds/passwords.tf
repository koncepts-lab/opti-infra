resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "^!@"
}

resource "aws_secretsmanager_secret" "db_master_password" {
  name                    = "${var.prefix}-db-master-password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_master_pwd_secret" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = random_password.master_password.result
}
