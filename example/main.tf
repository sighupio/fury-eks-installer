terraform {
  required_version = "0.15.4"
}

variable "cluster_name" {}
variable "cluster_version" {}
variable "network" {}
variable "subnetworks" { type = list }
variable "dmz_cidr_range" {}
variable "ssh_public_key" {}
variable "node_pools" { type = list }
variable "tags" {
  type = map
}

module "my-cluster" {
  source = "../modules/eks"

  cluster_version  = var.cluster_version
  cluster_name     = var.cluster_name
  network          = var.network
  subnetworks      = var.subnetworks
  ssh_public_key   = var.ssh_public_key
  dmz_cidr_range   = var.dmz_cidr_range
  node_pools       = var.node_pools
  eks_map_users    = null
  eks_map_roles    = null
  eks_map_accounts = []
  tags             = var.tags
}

output "kube_config" {
  sensitive = true
  value     = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: ${module.my-cluster.cluster_endpoint}
    certificate-authority-data: ${module.my-cluster.cluster_certificate_authority}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${var.cluster_name}"
EOT
}
