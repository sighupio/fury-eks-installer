locals {
  parsed_node_pools = [
    for worker in var.node_pools :
    map(
      "name", worker.name,
      "ami_id", element(data.aws_ami.eks_worker.*.image_id, index(var.node_pools.*.name, worker.name)),
      "min_size", worker.min_size,
      "max_size", worker.max_size,
      "instance_type", worker.instance_type,
      "volume_size", worker.volume_size,
      "kubelet_extra_args", <<EOT
--node-labels sighup.io/cluster=${var.cluster_name},sighup.io/node_pool=${worker.name},%{for k, v in worker.labels}${k}=${v},%{endfor}
EOT
    )
  ]
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "11.0.0"

  cluster_create_timeout                = "30m"
  cluster_delete_timeout                = "30m"
  cluster_endpoint_private_access       = true # SIGHUP only provides private clusters
  cluster_endpoint_private_access_cidrs = [var.dmz_cidr_range]
  cluster_endpoint_public_access        = false # SIGHUP only provides private clusters
  cluster_log_retention_in_days         = 90    # Default value
  cluster_name                          = var.cluster_name
  cluster_version                       = var.cluster_version
  create_eks                            = true
  eks_oidc_root_ca_thumbprint           = ""
  enable_irsa                           = false
  iam_path                              = "/${var.cluster_name}/"
  kubeconfig_name                       = var.cluster_name
  subnets                               = var.subnetworks
  vpc_id                                = var.network
  worker_additional_security_group_ids  = [aws_security_group.nodes.id]
  worker_groups = [
    for node_pool in local.parsed_node_pools :
    {
      name                          = lookup(node_pool, "name")
      ami_id                        = lookup(node_pool, "ami_id")
      asg_desired_capacity          = lookup(node_pool, "min_size")
      asg_max_size                  = lookup(node_pool, "max_size")
      asg_min_size                  = lookup(node_pool, "min_size")
      instance_type                 = lookup(node_pool, "instance_type")
      root_volume_size              = lookup(node_pool, "volume_size")
      key_name                      = aws_key_pair.nodes.key_name
      public_ip                     = false
      subnets                       = var.subnetworks
      additional_security_group_ids = [aws_security_group.nodes.id]
      cpu_credits                   = "unlimited" # Avoid t2/t3 throttling
      kubelet_extra_args            = trimsuffix(chomp(lookup(node_pool, "kubelet_extra_args")), ",")
    }
  ]
  worker_sg_ingress_from_port = 22
  write_kubeconfig            = false
}
