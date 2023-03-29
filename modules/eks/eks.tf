locals {
  default_node_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    "k8s.io/cluster-autoscaler/enabled" : "true"
  }

  worker_groups = [
    for node_pool in var.node_pools :
    {
      name = lookup(node_pool, "name")
      additional_security_group_ids = [
        aws_security_group.node_pool_shared.id,
        aws_security_group.node_pool[lookup(node_pool, "name")].id,
      ]
      ami_id = lookup(
        node_pool,
        "ami_id",
        data.aws_ami.eks_worker[lookup(node_pool, "name")].image_id,
      )
      asg_desired_capacity = lookup(node_pool, "min_size")
      asg_max_size         = lookup(node_pool, "max_size")
      asg_min_size         = lookup(node_pool, "min_size")
      bootstrap_extra_args = format(
        "%s%s",
        lookup(node_pool, "max_pods", null) != null ? " --use-max-pods false" : "",
        lookup(node_pool, "container_runtime", "") == "containerd" ? " --container-runtime containerd" : ""
      )
      cpu_credits = "unlimited" # Avoid t2/t3 throttling

      instance_type = lookup(node_pool, "instance_type")
      key_name      = aws_key_pair.nodes.key_name
      kubelet_extra_args = format(
        "%s%s%s",
        lookup(node_pool, "max_pods", null) != null ? " --max-pods ${lookup(node_pool, "max_pods")}" : "",
        join(",",
          merge(
            {
              " --node-labels=sighup.io/cluster" = var.cluster_name
              "sighup.io/node_pool"              = lookup(node_pool, "name")
              "node.kubernetes.io/lifecycle"     = lookup(node_pool, "spot_instance", false) ? "spot" : "ondemand"
            },
            lookup(node_pool, "labels", {})
          )
        ),
        length(lookup(node_pool, "taints", [])) > 0 ? " --register-with-taints ${join(",", lookup(node_pool, "taints"))}" : ""
      )
      public_ip        = false
      root_volume_size = lookup(node_pool, "volume_size")
      spot_price = lookup(
        node_pool,
        "spot_instance",
        false
      ) ? data.aws_ec2_spot_price.current[lookup(node_pool, "name")].spot_price * 2 : ""
      subnets = lookup(node_pool, "subnets", var.subnets)

      tags = [
        for key, value in merge(
          merge(
            local.default_node_tags,
            var.tags
          ),
          lookup(node_pool, "tags", {})
          ) : {
          key                 = key
          value               = value
          propagate_at_launch = true
      }]
      target_group_arns = lookup(node_pool, "target_group_arns", null)
    }
  ]
}

module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_create_timeout = "30m"
  cluster_delete_timeout = "30m"

  cluster_endpoint_private_access                = var.cluster_endpoint_private_access
  cluster_endpoint_private_access_cidrs          = var.cluster_endpoint_private_access_cidrs
  cluster_create_endpoint_private_access_sg_rule = true

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_log_retention_in_days = var.cluster_log_retention_days
  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  create_eks                    = true
  enable_irsa                   = true
  iam_path                      = "/${var.cluster_name}/"

  map_accounts = var.eks_map_accounts
  map_roles    = var.eks_map_roles
  map_users    = var.eks_map_users

  kubeconfig_name                      = var.cluster_name
  subnets                              = var.subnets
  tags                                 = var.tags
  vpc_id                               = var.vpc_id
  worker_additional_security_group_ids = [aws_security_group.node_pool_shared.id]
  worker_groups                        = var.node_pools_launch_kind == "launch_configurations" || var.node_pools_launch_kind == "both" ? local.worker_groups : []
  worker_groups_launch_template        = var.node_pools_launch_kind == "launch_templates" || var.node_pools_launch_kind == "both" ? local.worker_groups : []
  worker_sg_ingress_from_port          = 22
  write_kubeconfig                     = false
}
