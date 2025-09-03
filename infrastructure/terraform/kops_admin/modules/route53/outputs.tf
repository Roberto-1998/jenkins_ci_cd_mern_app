output "route53_ns_servers" {
  value = aws_route53_zone.primary.name_servers
}

output "route53_hosted_zone_name" {
  value = aws_route53_zone.primary.name
}