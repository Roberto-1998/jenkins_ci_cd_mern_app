

resource "aws_instance" "server" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  key_name        = var.instance_key_name
  security_groups = var.instance_security_groups

  tags = {
    Name = var.instance_name
  }
}