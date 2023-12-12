data "aws_subnet" "this" {
  for_each = toset(flatten(concat(
    var.subnets,
    flatten([
      for node_pool in var.node_pools : coalesce(lookup(node_pool, "subnets", null), [])
    ])
  )))
  vpc_id = var.vpc_id
  id     = each.value
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "zone-id"
    values = local.availability_zone_ids
  }
}

data "aws_region" "current" {}

data "aws_ami" "eks_worker" {
  for_each = {
    for node_pool in var.node_pools : node_pool["name"] => lookup(node_pool, "version", null)
  }

  filter {
    name   = "name"
    values = ["amazon-eks-node-${each.value != null ? each.value : var.cluster_version}-v*"]
  }

  most_recent = true

  owners = ["amazon"]
}

data "aws_ec2_spot_price" "current" {
  for_each = { for node_pool in var.node_pools : node_pool["name"] => node_pool["instance_type"] }
  # Fallback wth eu-west-1a when no availability zones are available
  availability_zone = length(data.aws_availability_zones.available.names) > 0 ? data.aws_availability_zones.available.names[0] : "eu-west-1a"
  instance_type     = each.value

  filter {
    name   = "product-description"
    values = ["Linux/UNIX"]
  }
}
