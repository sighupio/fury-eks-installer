resource "aws_key_pair" "nodes" {
  key_name_prefix = "${var.cluster_name}-"
  public_key      = var.ssh_public_key
}

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-"
  description = "Additional security group for nodes in ${var.cluster_name} EKS cluster"
  vpc_id      = var.network
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
  count = length(var.node_pool)

  filter {
    name   = "name"
    values = ["amazon-eks-node-${element(var.node_pool, count.index).version != null ? element(var.node_pool, count.index).version : var.cluster_version}-v*"]
  }

  most_recent = true

  owners = ["602401143452"]
}
