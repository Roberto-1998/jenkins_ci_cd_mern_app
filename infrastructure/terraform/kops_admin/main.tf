module "public_hosted_zone" {
  source           = "./modules/route53"
  hosted_zone_name = "kubeapp.rcginfo.xyz"
}


module "s3_bucket" {
  source         = "./modules/s3"
  s3_bucket_name = "kops-state-${random_string.kops_key_suffix.result}"

}

module "kops_admin_server_key" {
  source   = "./modules/keypair"
  key_name = "kops_admin_server_key"
  key_path = var.kops_admin_server_key_path
}

module "kops_admin_server_sg" {
  source                     = "./modules/secgroup"
  security_group_name        = "kops_admin_server_sg"
  security_group_description = "Security Group for Kops Admin Server"
  ingress_rules = [{
    cidr_ipv4   = "0.0.0.0/0",
    from_port   = 22,
    to_port     = 22,
    ip_protocol = "TCP"
  }]
}


module "kops_admin_server" {
  source                   = "./modules/ec2"
  instance_ami             = data.aws_ami.ubuntu.id
  instance_name            = "kops_admin_server"
  instance_type            = "t2.micro"
  instance_key_name        = module.kops_admin_server_key.key_name
  instance_security_groups = [module.kops_admin_server_sg.security_group_name]
}


