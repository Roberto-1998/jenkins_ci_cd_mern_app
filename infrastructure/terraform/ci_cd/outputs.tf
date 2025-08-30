output "jenkins_server_url" {
  value = "http://${module.jenkins_server.instance_public_ip}:8080"
}

output "jenkins_server_public_ip" {
  value = module.jenkins_server.instance_public_ip
}

output "jenkins_server_private_ip" {
  value = module.jenkins_server.instance_private_ip
}

