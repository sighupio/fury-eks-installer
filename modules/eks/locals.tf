locals {
  availability_zone_ids = toset([for subnet in data.aws_subnet.this : subnet.availability_zone_id])
  # Mapping from user-friendly AMI type names to actual AMI prefixes
  ami_type_prefix_map = {
    "alinux2"    = "amazon-eks-node"
    "alinux2023" = "amazon-eks-node-al2023-x86_64-standard"
  }

  # Determine the AMI prefix for each node pool: use the node pool-specific AMI type if defined, otherwise fall back to the global default
  node_pool_ami_prefix = {
    for node_pool in var.node_pools :
    node_pool.name => (
      contains(keys(local.ami_type_prefix_map), coalesce(node_pool.node_pool_ami_type, var.global_ami_type))
      ? local.ami_type_prefix_map[coalesce(node_pool.node_pool_ami_type, var.global_ami_type)]
      : local.ami_type_prefix_map[var.global_ami_type]
    )
  }
}