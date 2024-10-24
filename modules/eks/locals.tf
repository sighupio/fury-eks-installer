locals {
  availability_zone_ids = toset([for subnet in data.aws_subnet.this : subnet.availability_zone_id])
  # Mapping from user-friendly AMI type names to their respective prefixes
  ami_type_prefix_map = {
    "alinux2"           = "amazon-eks-node"                         # Amazon Linux 2 Standard
    "alinux2_gpu"       = "amazon-eks-gpu-node"                     # Amazon Linux 2 GPU
    "alinux2_arm64"     = "amazon-eks-arm64-node"                   # Amazon Linux 2 ARM64
    "alinux2023"        = "amazon-eks-node-al2023-x86_64-standard"  # Amazon Linux 2023 Standard x86_64
    "alinux2023_nvidia" = "amazon-eks-node-al2023-x86_64-nvidia"    # Amazon Linux 2023 NVIDIA x86_64
    "alinux2023_neuron" = "amazon-eks-node-al2023-x86_64-neuron"    # Amazon Linux 2023 Neuron x86_64
    "alinux2023_arm64"  = "amazon-eks-node-al2023-arm64-standard"   # Amazon Linux 2023 ARM64
  }

  # Determine the AMI prefix for each node pool, using the node pool-specific AMI type if defined, otherwise fall back to the global default
  node_pool_ami_prefix = {
    for node_pool in var.node_pools :
    node_pool.name => (
      contains(keys(local.ami_type_prefix_map), coalesce(node_pool.default_ami_type, var.global_eks_nodepool_default_ami_type))
      ? local.ami_type_prefix_map[coalesce(node_pool.default_ami_type, var.global_eks_nodepool_default_ami_type)]
      : local.ami_type_prefix_map[var.global_eks_nodepool_default_ami_type]
    )
  }
}