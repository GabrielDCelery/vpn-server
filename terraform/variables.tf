variable "aws_default_vpc_id" {
  description = "Default AWS VPC"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ssh_allow_list" {
  description = "Hosts that are allowed to SSH"
  type        = list(string)
}

variable "vpn_host_public_key" {
  description = "VPN host public key"
  type        = string
}
