locals {
  default_node_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    "k8s.io/cluster-autoscaler/enabled" : "true"
  }

  # Self-managed node groups
  worker_groups = [
    for node_pool in var.node_pools :
    {
      name = lookup(node_pool, "name")
      additional_security_group_ids = [
        aws_security_group.node_pool_shared.id,
        aws_security_group.node_pool[lookup(node_pool, "name")]["id"],
      ]
      ami_id               = data.aws_ami.eks_node_pool_ami_from_id[node_pool.name].image_id
      asg_desired_capacity = lookup(node_pool, "min_size")
      asg_max_size         = lookup(node_pool, "max_size")
      asg_min_size         = lookup(node_pool, "min_size")
      bootstrap_extra_args = format(
        "%s%s",
        lookup(node_pool, "max_pods", null) != null ? " --use-max-pods false" : "",
        lookup(node_pool, "container_runtime", null) == "containerd" ? " --container-runtime containerd" : ""
      )
      cpu_credits = "unlimited" # Avoid t2/t3 throttling

      instance_type = lookup(node_pool, "instance_type")
      key_name      = aws_key_pair.nodes.key_name
      kubelet_extra_args = format(
        "--node-labels %s%s%s",
        join(",",
          [
            for k, v in merge(
              {
                "sighup.io/cluster"   = var.cluster_name
                "sighup.io/node_pool" = lookup(node_pool, "name")
                "node.kubernetes.io/lifecycle" = coalesce(
                  lookup(node_pool, "spot_instance", null),
                  false
                ) ? "spot" : ""
              },
              lookup(node_pool, "labels", null) != null ? node_pool["labels"] : {}
            ) : "${k}=${v}"
          ]
        ),
        length(
          lookup(
            node_pool, "taints", null
          ) != null ? node_pool["taints"] : []
        ) > 0 ? " --register-with-taints ${join(",", lookup(node_pool, "taints"))}" : "",
        lookup(node_pool, "max_pods", null) != null ? " --max-pods ${lookup(node_pool, "max_pods")}" : "",
      )
      public_ip        = false
      root_volume_size = lookup(node_pool, "volume_size")
      root_volume_type = lookup(node_pool, "volume_type", "gp2")
      capacity_type = coalesce(
        lookup(node_pool, "spot_instance", null),
        false
      ) ? "SPOT" : null,
      spot_price = coalesce(
        lookup(node_pool, "spot_instance", null),
        false
      ) ? data.aws_ec2_spot_price.current[lookup(node_pool, "name")].spot_price : ""
      spot_max_price = coalesce(
        lookup(node_pool, "spot_instance", null),
        false
      ) ? data.aws_ec2_spot_price.current[lookup(node_pool, "name")].spot_price * 2 : ""
      market_type = coalesce(
        lookup(node_pool, "spot_instance", null),
        false
      ) ? "spot" : null,
      update_default_version = true
      subnets                = coalesce(lookup(node_pool, "subnets", null), var.subnets)

      tags = [
        for key, value in merge(
          merge(
            local.default_node_tags,
            var.tags
          ),
          coalesce(lookup(node_pool, "tags", null), {})
          ) : {
          key                 = key
          value               = value
          propagate_at_launch = true
        }
      ]
      target_group_arns = lookup(node_pool, "target_group_arns", null)
    } if lookup(node_pool, "type") == "self-managed" || lookup(node_pool, "type") == null
  ]

  taints_effect = {
    NoSchedule       = "NO_SCHEDULE"
    NoExecute        = "NO_EXECUTE"
    PreferNoSchedule = "PREFER_NO_SCHEDULE"
  }

  # EKS-managed node groups
  node_groups = [
    for node_pool in var.node_pools :
    {
      name             = lookup(node_pool, "name")
      ami_type         = local.eks_managed_node_pool_ami_type_map_by_type_and_arch["${coalesce(node_pool.ami_type, var.node_pools_global_ami_type)}-${data.aws_ami.eks_node_pool_ami_from_id[node_pool.name].architecture}"]
      desired_capacity = lookup(node_pool, "min_size")
      max_capacity     = lookup(node_pool, "max_size")
      min_capacity     = lookup(node_pool, "min_size")
      instance_types   = [lookup(node_pool, "instance_type")]
      key_name         = aws_key_pair.nodes.key_name
      k8s_labels = merge(
        {
          "sighup.io/cluster"   = var.cluster_name
          "sighup.io/node_pool" = lookup(node_pool, "name")
          "node.kubernetes.io/lifecycle" = coalesce(
            lookup(node_pool, "spot_instance", null),
            false
          ) ? "spot" : "ondemand"
        },
        coalesce(node_pool["labels"], {})
      )
      taints = [for taint in coalesce(node_pool["taints"], []) : {
        key    = split("=", taint)[0]
        value  = split(":", split("=", taint)[1])[0]
        effect = local.taints_effect[(split(":", taint)[1])]
      }]
      capacity_type = coalesce(
        lookup(node_pool, "spot_instance", null),
        false
      ) ? "SPOT" : "ON_DEMAND",
      subnets = coalesce(lookup(node_pool, "subnets", null), var.subnets)

      additional_tags = merge(
        var.tags,
        { Name : "${var.cluster_name}-${lookup(node_pool, "name")}" }
      )

    } if lookup(node_pool, "type") == "eks-managed"
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

  cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr

  cluster_log_retention_in_days = var.cluster_log_retention_days
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  create_eks                    = true
  enable_irsa                   = true
  iam_path                      = "/${var.cluster_name}/"
  cluster_iam_role_name         = var.cluster_iam_role_name

  map_accounts = var.eks_map_accounts
  map_roles    = var.eks_map_roles
  map_users    = var.eks_map_users

  kubeconfig_name = var.cluster_name
  subnets         = var.subnets
  tags            = var.tags
  vpc_id          = var.vpc_id

  # self-managed node groups
  worker_groups                        = var.node_pools_launch_kind == "launch_configurations" || var.node_pools_launch_kind == "both" ? local.worker_groups : []
  worker_groups_launch_template        = var.node_pools_launch_kind == "launch_templates" || var.node_pools_launch_kind == "both" ? local.worker_groups : []
  workers_group_defaults               = {}
  worker_additional_security_group_ids = [aws_security_group.node_pool_shared.id]
  worker_sg_ingress_from_port          = 22
  workers_role_name                    = var.workers_role_name

  # eks-managed node groups
  node_groups          = local.node_groups
  node_groups_defaults = {}

  write_kubeconfig = false
}

resource "aws_iam_role_policy_attachment" "workers_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.cluster.worker_iam_role_name
}
