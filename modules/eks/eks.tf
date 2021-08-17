locals {

  default_node_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    "k8s.io/cluster-autoscaler/enabled" : "true"
  }

  parsed_node_pools = [
    for worker in var.node_pools :
    {
      "name" : worker.name,
      "ami_id" : worker.ami_id != null ? worker.ami_id : element(data.aws_ami.eks_worker.*.image_id, index(var.node_pools.*.name, worker.name)),
      "security_group_id" : element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, worker.name)),
      "min_size" : worker.min_size,
      "max_size" : worker.max_size,
      "instance_type" : worker.instance_type,
      "tags" : [for tag_key, tag_value in merge(merge(local.default_node_tags, var.tags), worker.tags) : { "key" : tag_key, "value" : tag_value, "propagate_at_launch" : true }],
      "volume_size" : worker.volume_size,
      "subnetworks" : worker.subnetworks != null ? worker.subnetworks : var.subnetworks
      "eks_target_group_arns" : worker.eks_target_group_arns
      "bootstrap_extra_args" : "%{if lookup(worker, "max_pods", null) != null}--use-max-pods false%{endif}",
      "kubelet_extra_args" : <<EOT
%{if lookup(worker, "max_pods", null) != null}--max-pods ${worker.max_pods} %{endif}--node-labels sighup.io/cluster=${var.cluster_name},sighup.io/node_pool=${worker.name},%{for k, v in worker.labels}${k}=${v},%{endfor}
%{if length(worker.taints) > 0}--register-with-taints %{for t in worker.taints}${t},%{endfor}%{endif}
EOT
    }
  ]
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "16.2.0"

  cluster_create_timeout                         = "30m"
  cluster_delete_timeout                         = "30m"
  cluster_endpoint_private_access                = true # SIGHUP only provides private clusters
  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access_cidrs          = local.parsed_dmz_cidr_range
  cluster_endpoint_public_access                 = false # SIGHUP only provides private clusters
  cluster_log_retention_in_days                  = 90    # Default value
  cluster_enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_name                                   = var.cluster_name
  cluster_version                                = var.cluster_version
  create_eks                                     = true
  enable_irsa                                    = true
  iam_path                                       = "/${var.cluster_name}/"

  map_accounts = var.eks_map_accounts
  map_roles    = var.eks_map_roles
  map_users    = var.eks_map_users

  kubeconfig_name                      = var.cluster_name
  subnets                              = var.subnetworks
  tags                                 = var.tags
  vpc_id                               = var.network
  worker_additional_security_group_ids = [aws_security_group.nodes.id]
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
      target_group_arns             = lookup(node_pool, "eks_target_group_arns")
      key_name                      = aws_key_pair.nodes.key_name
      public_ip                     = false
      subnets                       = lookup(node_pool, "subnetworks")
      additional_security_group_ids = [aws_security_group.nodes.id, lookup(node_pool, "security_group_id")]
      cpu_credits                   = "unlimited" # Avoid t2/t3 throttling
      kubelet_extra_args            = replace(trimsuffix(chomp(lookup(node_pool, "kubelet_extra_args")), ","), "\n", " ")
      tags                          = lookup(node_pool, "tags")
      bootstrap_extra_args          = lookup(node_pool, "bootstrap_extra_args")
    }
  ]
  worker_sg_ingress_from_port = 22
  write_kubeconfig            = false
}
