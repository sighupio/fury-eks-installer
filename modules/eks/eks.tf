locals {

  default_node_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    "k8s.io/cluster-autoscaler/enabled" : "true"
  }

  parsed_node_pools = [
    for worker in var.node_pools :
    {
      "name" : worker.name,
      "os" : worker.os != null ? worker.os : element(data.aws_ami.eks_worker.*.image_id, index(var.node_pools.*.name, worker.name)),
      "security_group_id" : element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, worker.name)),
      "min_size" : worker.min_size,
      "max_size" : worker.max_size,
      // we make the double of the current given spot_price to avoid any price volatily.
      "spot_instance_price" : worker.spot_instance ? element(data.aws_ec2_spot_price.current.*.spot_price, index(var.node_pools.*.name, worker.name)) * 2 : "",
      "instance_type" : worker.instance_type,
      "tags" : [for tag_key, tag_value in merge(merge(local.default_node_tags, var.tags), worker.tags) : { "key" : tag_key, "value" : tag_value, "propagate_at_launch" : true }],
      "volume_size" : worker.volume_size,
      "subnetworks" : worker.subnetworks != null ? worker.subnetworks : var.subnetworks
      "eks_target_group_arns" : worker.eks_target_group_arns
      "bootstrap_extra_args" : "%{if lookup(worker, "max_pods", null) != null}--use-max-pods false%{endif}",
      "kubelet_extra_args" : <<EOT
%{if lookup(worker, "max_pods", null) != null}--max-pods ${worker.max_pods} %{endif}--node-labels=sighup.io/cluster=${var.cluster_name},sighup.io/node_pool=${worker.name},%{for k, v in worker.labels}${k}=${v},%{endfor}${worker.spot_instance ? "node.kubernetes.io/lifecycle=spot" : ""}
%{if length(worker.taints) > 0}--register-with-taints %{for t in worker.taints}${t},%{endfor}%{endif}
EOT
    }
  ]

  worker_groups = [
    for node_pool in local.parsed_node_pools :
    {
      name                          = lookup(node_pool, "name")
      ami_id                        = lookup(node_pool, "os")
      asg_desired_capacity          = lookup(node_pool, "min_size")
      asg_max_size                  = lookup(node_pool, "max_size")
      asg_min_size                  = lookup(node_pool, "min_size")
      instance_type                 = lookup(node_pool, "instance_type")
      root_volume_size              = lookup(node_pool, "volume_size")
      target_group_arns             = lookup(node_pool, "eks_target_group_arns")
      key_name                      = aws_key_pair.nodes.key_name
      public_ip                     = false
      spot_price                    = lookup(node_pool, "spot_instance_price")
      subnets                       = lookup(node_pool, "subnetworks")
      additional_security_group_ids = [aws_security_group.nodes.id, lookup(node_pool, "security_group_id")]
      cpu_credits                   = "unlimited" # Avoid t2/t3 throttling
      kubelet_extra_args            = replace(trimsuffix(chomp(lookup(node_pool, "kubelet_extra_args")), ","), "\n", " ")
      tags                          = lookup(node_pool, "tags")
      bootstrap_extra_args          = lookup(node_pool, "bootstrap_extra_args")
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
  cluster_log_retention_in_days                  = var.cluster_log_retention_days
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
  worker_groups                        = var.node_pools_kind == "launch_configurations" || var.node_pools_kind == "both" ? local.worker_groups : []
  worker_groups_launch_template        = var.node_pools_kind == "launch_templates" || var.node_pools_kind == "both" ? local.worker_groups : []
  worker_sg_ingress_from_port          = 22
  write_kubeconfig                     = false
}
