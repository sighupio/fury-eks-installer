resource "aws_key_pair" "nodes" {
  key_name_prefix = "${var.cluster_name}-"
  public_key      = var.ssh_public_key
  tags            = var.tags
}

resource "aws_security_group" "node_pool" {
  count = length(var.node_pools)

  vpc_id      = var.network
  name        = "${var.cluster_name}-nodepool-${var.node_pools[count.index].name}"
  description = "Additional security group for the node pool ${var.node_pools[count.index].name} in the ${var.cluster_name} cluster"

  tags = merge(
    # Map of tags in the cluster
    var.tags,
    # Map of tags in the node pool
    var.node_pools[count.index].tags,
    # Map of all the tags in the rules
    # https://stackoverflow.com/questions/57392101/merge-maps-inside-list-in-terraform
    zipmap(flatten([for item in var.node_pools[count.index].additional_firewall_rules.*.tags : keys(item)]), flatten([for item in var.node_pools[count.index].additional_firewall_rules.*.tags : values(item)]))
  )
}

locals {
  sg_rules = flatten([
    [for nodePool in var.node_pools : [
      [for rule in nodePool.additional_firewall_rules : {
        security_group_id = element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, nodePool.name)),
        type              = rule.direction
        from_port         = split("-", rule.ports)[0]
        to_port           = split("-", rule.ports)[1]
        protocol          = rule.protocol
        cidr_blocks       = [rule.source_cidr]
      }]
      ]
    ]
  ])
}

resource "aws_security_group_rule" "node_pool" {
  count = length(local.sg_rules)

  type              = local.sg_rules[count.index]["type"]
  from_port         = local.sg_rules[count.index]["from_port"]
  to_port           = local.sg_rules[count.index]["to_port"]
  protocol          = local.sg_rules[count.index]["protocol"]
  cidr_blocks       = local.sg_rules[count.index]["cidr_blocks"]
  security_group_id = local.sg_rules[count.index]["security_group_id"]
}

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-"
  description = "Additional security group for nodes in ${var.cluster_name} EKS cluster"
  vpc_id      = var.network
  tags        = var.tags
}

resource "aws_security_group_rule" "ssh_from_dmz_to_nodes" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.dmz_cidr_range]
  security_group_id = aws_security_group.nodes.id
}

data "aws_ami" "eks_worker" {
  count = length(var.node_pools)

  filter {
    name   = "name"
    values = ["amazon-eks-node-${element(var.node_pools, count.index).version != null ? element(var.node_pools, count.index).version : var.cluster_version}-v*"]
  }

  most_recent = true

  owners = ["602401143452"]
}
