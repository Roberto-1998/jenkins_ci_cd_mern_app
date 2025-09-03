output "security_group_name" {
  value = aws_security_group.server-sg.name
}

output "security_group_id" {
  value = aws_security_group.server-sg.id
}