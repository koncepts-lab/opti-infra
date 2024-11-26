output "db_master_password" {
  value = data.aws_secretsmanager_secret_version.password.secret_string
  description = "the value of the db administrator password"
}

output "db_master_pwd_secret_arn" {
    value = aws_secretsmanager_secret_version.db_master_pwd_secret.arn
    description = "the arn for the secrets created for the db master password"
}