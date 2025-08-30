
/* Once created at local upload public key to AWS */
module "servers_key_pair" {
  source   = "./modules/keypair"
  key_name = "server_key_pair"
  key_path = "~/.ssh/jenkins-key.pub"
}

/* Segurity groups  */
module "security_groups" {
  source                     = "./modules/secgroup"
  security_group_name        = "jenkins_server_sg"
  security_group_description = "Security Group for Jenkins Server"
  ingress_rules = [{
    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 80
    to_port     = 80
    ip_protocol = "TCP"
    },
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      ip_protocol = "TCP"
    },
    {
      cidr_ipv4   = "${local.my_ip}/32"
      from_port   = 22
      to_port     = 22
      ip_protocol = "TCP"
    },
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "TCP"
    },


  ]
}