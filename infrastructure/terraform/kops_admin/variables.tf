variable "AWS_REGION" {
  description = "AWS Region"
  validation {
    condition     = var.AWS_REGION == "us-east-1"
    error_message = "Only us-east-1 is allowed"
  }
}