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

  # Be careful with: https://github.com/hashicorp/terraform/issues/22605
  dynamic "ingress" {
    for_each = [for rule in var.node_pools[count.index].additional_firewall_rules : rule if rule.direction == "ingress"]
    content {
      description = ingress.value.name
      from_port   = split("-", ingress.value.ports)[0]
      to_port     = split("-", ingress.value.ports)[1]
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.source_cidr]
    }
  }

  # Be careful with: https://github.com/hashicorp/terraform/issues/22605
  dynamic "egress" {
    for_each = [for rule in var.node_pools[count.index].additional_firewall_rules : rule if rule.direction == "egress"]
    content {
      description = egress.value.name
      from_port   = split("-", egress.value.ports)[0]
      to_port     = split("-", egress.value.ports)[1]
      protocol    = egress.value.protocol
      cidr_blocks = [egress.value.source_cidr]
    }
  }

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
