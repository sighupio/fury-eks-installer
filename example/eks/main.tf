data "terraform_remote_state" "vpc_and_vpn" {
  backend = "local"
  config = {
    path = "${path.module}/../vpc-and-vpn/terraform.tfstate"
  }
}

module "fury_example" {
  source = "../../modules/eks"

  cluster_name    = "fury-example"
  cluster_version = "1.23"

  network     = data.terraform_remote_state.vpc_and_vpn.outputs.vpc_id
  subnetworks = data.terraform_remote_state.vpc_and_vpn.outputs.public_subnets

  ssh_public_key = var.ssh_public_key
  dmz_cidr_range = "10.0.4.0/24"

  node_pools = [
    {
      name : "m5-node-pool"
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
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
            "cluster-tags" : "my-value-OVERRIDE-1"
          }
        }
      ]
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.23.1"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    },{
      name : "m5-node-pool-spot"
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      spot_instance : true # optionally create spot instances
      os : "ami-0caf35bc73450c396" # optionally define a custom AMI
      volume_size : 100
      subnetworks : null
      eks_target_group_arns : null
      additional_firewall_rules : [
        {
          name : "Debug 2"
          direction : "ingress"
          cidr_block : "0.0.0.0/0"
          protocol : "TCP"
          ports : "80-80"
          tags : {
            "hello" : "tag",
            "cluster-tags" : "my-value-OVERRIDE-2"
          }
        }
      ]
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.23.1"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    },
  ]

  tags = {
    Environment: "example"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
