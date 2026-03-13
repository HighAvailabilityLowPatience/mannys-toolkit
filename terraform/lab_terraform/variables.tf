# AWS region to deploy resources into
variable "region" {
  description = "AWS region"
  type        = string
}

# EC2 key pair name for SSH access
variable "key_name" {
  description = "Name of existing AWS key pair"
  type        = string
}

# Instance type
variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro"
}
