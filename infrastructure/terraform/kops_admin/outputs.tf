output "hosted_zone_name" {
  value = module.public_hosted_zone.route53_hosted_zone_name
}

output "hosted_zone_name_ns_servers" {
  value = module.public_hosted_zone.route53_ns_servers
}

output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_name
}

output "kops_server_admin_keypair_path" {
  value = var.kops_admin_server_key_path
}