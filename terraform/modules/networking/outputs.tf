output "vpc_id" {
  value       = aws_vpc.mainvpc.id
  description = "The vpc id of the vpc being created by this module"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet[*].id
  description = "the id of the public subnets"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet[*].id
  description = "the id of the private subnets"
}

output "public_subnets" {
  value       = aws_subnet.public_subnet
  description = "the public subnets"
}

output "private_subnets" {
  value       = aws_subnet.private_subnet
  description = "the private subnets"
}


output "default_sg" {
  value       = aws_default_security_group.default_sg
  description = "the default security group"
}
