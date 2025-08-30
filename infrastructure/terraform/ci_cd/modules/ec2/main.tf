

resource "aws_instance" "server" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  key_name        = var.instance_key_name
  security_groups = var.instance_security_groups
  root_block_device {
    volume_type = var.instance_volume_type
    volume_size = 25
  }


  tags = {
    Name = var.instance_name
  }
}