terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# resource "aws_default_vpc" "vpc" {}

# import {
#   to = aws_default_vpc.vpc
#   id = var.aws_default_vpc_id
# }

data "aws_vpc" "default_vpc" {
  id = var.aws_default_vpc_id
}

resource "aws_key_pair" "deployer" {
  key_name   = "vpn_host_key"
  public_key = var.vpn_host_public_key
}

resource "aws_security_group" "allow_inbound_ssh" {
  name        = "allow_inbound_ssh"
  description = "Allows inbound ssh"
  vpc_id      = data.aws_vpc.default_vpc.id

  tags = {
    Name = "allow_inbound_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  for_each = toset(var.ssh_allow_list)

  security_group_id = aws_security_group.allow_inbound_ssh.id
  cidr_ipv4         = each.key
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_security_group" "allow_outbound_all" {
  name        = "allow_outbound_all"
  description = "Allows outbound all"
  vpc_id      = data.aws_vpc.default_vpc.id

  tags = {
    Name = "allow_outbound_all"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_all" {
  security_group_id = aws_security_group.allow_outbound_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "vpn_host" {
  ami             = "ami-091f18e98bc129c4e"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_inbound_ssh.name, aws_security_group.allow_outbound_all.name]
  key_name        = aws_key_pair.deployer.id
}

output "vpn_host_ip" {
  description = "Public IP of the VPN Host"
  value       = aws_instance.vpn_host.public_ip
}

resource "null_resource" "example" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.vpn_host.public_ip
      user        = "ubuntu"
      private_key = file("~/.ssh/root.any")
    }

    inline = ["echo 'connected!'"]
  }
}
