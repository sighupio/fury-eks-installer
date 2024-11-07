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

data "aws_ec2_instance_type" "eks_worker" {
  for_each = {
    for node_pool in var.node_pools : node_pool.name => node_pool
  }

  instance_type = each.value.instance_type
}

# Fetch the default AMI to use for each node pool
data "aws_ami" "eks_worker_default_ami" {
  for_each = {
    for node_pool in var.node_pools : node_pool["name"] => coalesce(node_pool.version, var.cluster_version)
  }

  filter {
    name   = "name"
    values = ["${local.node_pool_ami_name_prefix[each.key]}-${each.value}-v*"]
  }

  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.eks_worker[each.key].supported_architectures
  }

  most_recent = true
  owners      = ["amazon"]
}

# Gather data for each node pool AMI. It fetch data also in case of specified ami id/ami owner
data "aws_ami" "eks_node_pool_from_ami_id" {
  for_each = local.node_pool_ami

  filter {
    name   = "image-id"
    values = [each.value.ami_id]
  }
  owners = each.value.owners
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
