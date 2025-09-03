variable "instance_name" {
  type        = string
  description = "Instance name"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "instance_ami" {
  type        = string
  description = "Instance AMI"
}

variable "instance_key_name" {
  type        = string
  description = "Instance Key Pair name"
}

variable "instance_security_groups" {
  type        = list(string)
  description = "List of Security Groups for the instance"
}

