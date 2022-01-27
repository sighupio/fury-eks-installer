terraform {
  required_version = "0.15.4"
}

module "my-cluster" {
  source = "../../modules/eks"

  cluster_name    = "my-cluster"
  cluster_version = "1.14"

  network         = "vpc-id0"
  subnetworks = [
    "subnet-id1",
    "subnet-id2",
    "subnet-id3",
  ]

  ssh_public_key = "ssh-rsa example"
  dmz_cidr_range = "10.0.4.0/24"
  
  node_pools = [
    {
      name : "m5-node-pool"
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      spot_instance : true
      volume_size : 100
      subnetworks : null
      eks_target_group_arns : null
      additional_firewall_rules : [
        {
          name : "Debug 1"
          direction : "ingress"
          cidr_block : "0.0.0.0/0"
          protocol : "TCP"
          ports : "80-80"
          tags : {
            "hello" : "tag",
            "cluster-tags" : "my-value-OVERRIDE"
          }
        }
      ]
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.23.0"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    },
  ]

  tags = {
    "my-tags" : "my-value"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
