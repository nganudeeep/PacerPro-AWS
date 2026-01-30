variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = null
}

variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "shared_secret" {
  type      = string
  sensitive = true
  default   = "abc123"
}

variable "sns_email_subscription" {
  type    = string
  default = null
}
