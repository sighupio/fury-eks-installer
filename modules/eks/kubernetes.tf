data "aws_eks_cluster" "cluster" {
  name = module.cluster.cluster_id
}

