

resource "aws_instance" "server" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  key_name        = var.instance_key_name
  security_groups = var.instance_security_groups

  iam_instance_profile = aws_iam_instance_profile.kops_profile.name

  tags = {
    Name = var.instance_name
  }
}


resource "aws_iam_role" "kops_role" {
  name = "kops-admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Empieza con algo amplio para acelerar, luego reduce a mínimo necesario
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.kops_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "kops_profile" {
  name = "kops-admin-profile"
  role = aws_iam_role.kops_role.name
}
