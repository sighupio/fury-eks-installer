data "aws_vpc" "this" {
  id = var.vpc_id
}

data "external" "os" {
  program = ["${path.module}/bin/os.sh"]
}

data "aws_region" "current" {}

data "aws_ami" "ubuntu2004" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    ]
  }
  filter {
    name = "image-type"
    values = [
      "machine"
    ]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"
    ]
  }
}