resource "random_string" "kops_key_suffix" {
  length  = 8
  upper   = false
  lower   = true
  special = false
}