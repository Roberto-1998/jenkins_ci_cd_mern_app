variable "AWS_REGION" {
  description = "AWS Region"
  validation {
    condition     = var.AWS_REGION == "us-east-1"
    error_message = "Only us-east-1 is allowed"
  }
}

variable "kops_admin_server_key_path" {
  type        = string
  description = "Local path for public server key"

}