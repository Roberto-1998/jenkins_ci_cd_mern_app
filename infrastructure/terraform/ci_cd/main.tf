
/* Once created at local upload public key to AWS */
module "servers_key_pair" {
  source   = "./modules/keypair"
  key_name = "server_key_pair"
  key_path = "~/.ssh/jenkins-key.pub"
}

/* Security groups  */
module "jenkins_server_sg" {
  source                     = "./modules/secgroup"
  security_group_name        = "jenkins_server_sg"
  security_group_description = "Security Group for Jenkins Server"
  ingress_rules              = local.jenkins_server_ingress_rules
}

/* EC2 Servers */
module "jenkins_server" {
  source                   = "./modules/ec2"
  instance_name            = "jenkins-server"
  instance_type            = local.instance_type
  instance_ami             = data.aws_ami.ubuntu.id
  instance_key_name        = module.servers_key_pair.key_name
  instance_security_groups = [module.jenkins_server_sg.security_group_name]
  instance_volume_size     = local.instance_volume_size
  instance_volume_type     = "gp3"
}