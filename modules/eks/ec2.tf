resource "aws_key_pair" "nodes" {
  key_name_prefix = "${var.cluster_name}-"
  public_key      = var.ssh_public_key
  tags            = var.tags
}

resource "aws_security_group" "node_pool" {
  for_each = {
    for node_pool in var.node_pools :
    node_pool["name"] => {
      tags                      = lookup(node_pool, "tags", {})
      additional_firewall_rules = lookup(node_pool, "additional_firewall_rules", {})
    }
  }

  vpc_id      = var.vpc_id
  name        = "${var.cluster_name}-nodepool-${each.key}"
  description = "Additional security group for the node pool ${each.key} in the ${var.cluster_name} cluster"

  tags = merge(
    # Map of tags in the cluster
    var.tags,
    # Map of tags in the node pool
    each.value["tags"],
    # Map of all the tags in the rules
    # https://stackoverflow.com/questions/57392101/merge-maps-inside-list-in-terraform
    zipmap(
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "cidr_blocks", []) : [
          keys(lookup(rule, "tags", {}))
        ]
      ]),
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "cidr_blocks", []) : [
          values(lookup(rule, "tags", {}))
        ]
      ])
    ),
    zipmap(
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "self", []) : [
          keys(lookup(rule, "tags", {}))
        ]
      ]),
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "self", []) : [
          values(lookup(rule, "tags", {}))
        ]
      ])
    ),
    zipmap(
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "source_security_group_id", []) : [
          keys(lookup(rule, "tags", {}))
        ]
      ]),
      flatten([
        for rule in lookup(each.value["additional_firewall_rules"], "source_security_group_id", []) : [
          values(lookup(rule, "tags", {}))
        ]
      ])
    )
  )
}

locals {
  additional_firewall_rules_cidr_blocks = flatten([
    for nodePool in var.node_pools :
    [
      for rule in lookup(
        lookup(nodePool, "additional_firewall_rules", {}),
        "cidr_blocks",
        []
        ) : {
        security_group_id = element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, nodePool["name"])),
        type              = lookup(rule, "type")
        from_port         = lookup(rule, "from_port")
        to_port           = lookup(rule, "to_port")
        protocol          = lookup(rule, "protocol")
        cidr_blocks       = lookup(rule, "cidr_blocks")
      }
    ]
  ])
  additional_firewall_rules_source_security_group_id = flatten([
    for nodePool in var.node_pools :
    [
      for rule in lookup(
        lookup(nodePool, "additional_firewall_rules", {}),
        "source_security_group_id",
        []
        ) : {
        security_group_id        = element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, nodePool["name"])),
        type                     = lookup(rule, "type")
        from_port                = lookup(rule, "from_port")
        to_port                  = lookup(rule, "to_port")
        protocol                 = lookup(rule, "protocol")
        source_security_group_id = lookup(rule, "source_security_group_id")
      }
    ]
  ])
  additional_firewall_rules_self = flatten([
    for nodePool in var.node_pools :
    [
      for rule in lookup(
        lookup(nodePool, "additional_firewall_rules", {}),
        "self",
        []
        ) : {
        security_group_id = element(aws_security_group.node_pool.*.id, index(var.node_pools.*.name, nodePool["name"])),
        type              = lookup(rule, "type")
        from_port         = lookup(rule, "from_port")
        to_port           = lookup(rule, "to_port")
        protocol          = lookup(rule, "protocol")
        self              = lookup(rule, "self")
      }
    ]
  ])
}

resource "aws_security_group_rule" "node_pool_additional_firewall_rules_cidr_blocks" {
  count = length(local.additional_firewall_rules_cidr_blocks)

  type              = local.additional_firewall_rules_cidr_blocks[count.index]["type"]
  from_port         = local.additional_firewall_rules_cidr_blocks[count.index]["from_port"]
  to_port           = local.additional_firewall_rules_cidr_blocks[count.index]["to_port"]
  protocol          = local.additional_firewall_rules_cidr_blocks[count.index]["protocol"]
  cidr_blocks       = local.additional_firewall_rules_cidr_blocks[count.index]["cidr_blocks"]
  security_group_id = local.additional_firewall_rules_cidr_blocks[count.index]["security_group_id"]
}

resource "aws_security_group_rule" "node_pool_additional_firewall_rules_source_security_group_id" {
  count = length(local.additional_firewall_rules_source_security_group_id)

  type                     = local.additional_firewall_rules_source_security_group_id[count.index]["type"]
  from_port                = local.additional_firewall_rules_source_security_group_id[count.index]["from_port"]
  to_port                  = local.additional_firewall_rules_source_security_group_id[count.index]["to_port"]
  protocol                 = local.additional_firewall_rules_source_security_group_id[count.index]["protocol"]
  source_security_group_id = local.additional_firewall_rules_source_security_group_id[count.index]["source_security_group_id"]
  security_group_id        = local.additional_firewall_rules_source_security_group_id[count.index]["security_group_id"]
}

resource "aws_security_group_rule" "node_pool_additional_firewall_rules_self" {
  count = length(local.additional_firewall_rules_self)

  type              = local.additional_firewall_rules_self[count.index]["type"]
  from_port         = local.additional_firewall_rules_self[count.index]["from_port"]
  to_port           = local.additional_firewall_rules_self[count.index]["to_port"]
  protocol          = local.additional_firewall_rules_self[count.index]["protocol"]
  self              = local.additional_firewall_rules_self[count.index]["self"]
  security_group_id = local.additional_firewall_rules_self[count.index]["security_group_id"]
}

resource "aws_security_group" "node_pool_shared" {
  name_prefix = "${var.cluster_name}-"
  description = "Additional security group for nodes in ${var.cluster_name} EKS cluster"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "ssh_to_nodes" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_to_nodes_allowed_cidr_blocks != null ? var.ssh_to_nodes_allowed_cidr_blocks : var.cluster_endpoint_private_access_cidrs
  security_group_id = aws_security_group.node_pool_shared.id
}
