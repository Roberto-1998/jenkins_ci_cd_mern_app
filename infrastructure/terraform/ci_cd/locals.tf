locals {
  my_ip = chomp(data.http.my_ip.response_body)

  instance_type = terraform.workspace == "prod" ? "t2.medium" : "t2.small"

  instance_volume_size = terraform.workspace == "prod" ? 30 : 25

  jenkins_server_ingress_rules = [{
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