locals {
  default_vpc_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = var.name
  cidr = var.network_cidr

  azs = data.aws_availability_zones.available.names

  private_subnets = var.private_subnetwork_cidrs
  public_subnets  = var.public_subnetwork_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = merge(local.default_vpc_tags, var.tags)

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}
