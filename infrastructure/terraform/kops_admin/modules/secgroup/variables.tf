variable "security_group_name" {
  type        = string
  description = "Security group name"
}


variable "security_group_description" {
  type        = string
  description = "Security group description"
}

variable "security_group_vpc_id" {
  type        = string
  description = "Security group VPC ID"
  default     = null
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    cidr_ipv4   = string
    from_port   = string
    ip_protocol = string
    to_port     = string
  }))
  default = null
}