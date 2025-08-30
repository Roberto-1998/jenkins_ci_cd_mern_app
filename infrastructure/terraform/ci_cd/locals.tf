locals {
  my_ip = chomp(data.http.my_ip.response_body)
}