resource "aws_key_pair" "kops_admin_server_key" {
  key_name   = var.key_name
  public_key = file(var.key_path)
}