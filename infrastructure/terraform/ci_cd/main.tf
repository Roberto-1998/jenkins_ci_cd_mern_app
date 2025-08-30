
/* Once created at local upload public key to AWS */
module "servers_key_pair" {
  source = "./modules/keypair"
  key_name = "server_key_pair"
  key_path = "~/.ssh/jenkins-key.pub"
}