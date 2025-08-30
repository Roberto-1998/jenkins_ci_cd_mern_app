variable "AWS_REGION" {
  description = "AWS allowed region for this project"
  type        = string
  validation {
    condition     = var.AWS_REGION == "us-east-1"
    error_message = "Only us-east-1 region es allowed"
  }
}