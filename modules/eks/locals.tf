locals {
  availability_zone_ids = toset([for subnet in data.aws_subnet.this : subnet.availability_zone_id])

  # Mapping from user-friendly AMI type names to actual AMI prefixes
  ami_name_prefix_map_by_type = {
    "alinux2"    = "amazon-eks(-arm64)?-node"
    "alinux2023" = "amazon-eks-node-al2023-(arm64|x86_64)-standard"
  }

  # Mapping EKS Managed `ami_type` from user-friendly AMI prefixes
  eks_managed_node_pool_ami_type_map_by_type_and_arch = {
    alinux2-x86_64    = "AL2_x86_64"
    alinux2-arm64     = "AL2_ARM_64"
    alinux2023-x86_64 = "AL2023_x86_64_STANDARD"
    alinux2023-arm64  = "AL2023_ARM_64_STANDARD"
  }

  # Determine the AMI prefix for each node pool: use the node pool-specific AMI type if defined, otherwise fall back to the global default
  node_pool_ami_name_prefix = {
    for node_pool in var.node_pools :
    node_pool.name => (
      lookup(local.ami_name_prefix_map_by_type, coalesce(node_pool.ami_type, var.node_pools_global_ami_type))
    )
  }

  # Determine the AMI ID and owners for each node pool
  node_pool_ami = {
    for node_pool in var.node_pools :
    node_pool.name => {
      ami_id = coalesce(node_pool.ami_id, data.aws_ami.eks_worker_default_ami[lookup(node_pool, "name")].image_id)
      owners = coalesce(node_pool.ami_owners, data.aws_ami.eks_worker_default_ami[lookup(node_pool, "name")].owners)
    }
  }
}