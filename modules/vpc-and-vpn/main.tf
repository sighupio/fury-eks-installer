terraform {
  required_version = ">= 1.3"
  required_providers {
    local    = "~> 2.1"
    null     = "~> 3.1"
    aws      = "~> 3.56"
    external = "~> 2.1"
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

locals {
  # https://cloud-images.ubuntu.com/locator/ec2/
  # filter: 20.04 LTS eu- ebs-ssd 2020 amd64
  ubuntu_amis = {
    "eu-west-3" : "ami-098efdd0afb686fd5"
    "eu-west-2" : "ami-099ae17a6a688b1cc"
    "eu-west-1" : "ami-048309a44dad514df"
    "eu-south-1" : "ami-0e3c0649c89ccddc9"
    "eu-north-1" : "ami-01450210d4ebb3bab"
    "eu-central-1" : "ami-09f14afb2e15caab5"
    "us-east-1" : "ami-0c4f7023847b90238"
  }
}
