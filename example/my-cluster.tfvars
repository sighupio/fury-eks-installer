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
tags = {
  "cluster-tags" : "also-exists"
}
node_pools = [
  {
    name : "m5-node-pool"
    version : null # To use same value as cluster_version
    min_size : 1
    max_size : 2
    instance_type : "m5.large"
    spot_instance: true
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
          "cluster-tags" : "also-exists-OVERRIDE"
        }
      },
      {
        name : "Debug 2"
        direction : "egress"
        cidr_block : "0.0.0.0/0"
        protocol : "TCP"
        ports : "80-111"
        tags : {
          "ciao" : "a tutti"
        }
      }
    ]
    labels : {
      "node.kubernetes.io/role" : "app"
      "sighup.io/fury-release" : "v1.3.0"
    }
    taints : []
    tags : {
      "node-tags" : "exists"
    }
    # max_pods : null # To use default EKS setting set it to null or do not set it
  },
  {
    name : "t3-node-pool"
    version : "1.14" # To use the cluster_version
    min_size : 1
    max_size : 1
    instance_type : "t3.micro"
    spot_instance: false
    volume_size : 50
    subnetworks : null
    eks_target_group_arns : null
    additional_firewall_rules : []
    labels : {}
    taints : [
      "sighup.io/role=app:NoSchedule"
    ]
    tags : {}
    max_pods : 123 # To use specific value
  }
]
