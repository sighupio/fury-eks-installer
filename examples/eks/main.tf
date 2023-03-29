data "terraform_remote_state" "vpc_and_vpn" {
  backend = "local"
  config = {
    path = "${path.module}/../vpc-and-vpn/terraform.tfstate"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "fury_example" {
  source = "../../modules/eks"

  cluster_name    = "fury-example"  # make sure to use the same name you used in the VPC and VPN module
  cluster_version = "1.25"

  vpc_id      = data.terraform_remote_state.vpc_and_vpn.outputs.vpc_id
  subnetworks = data.terraform_remote_state.vpc_and_vpn.outputs.private_subnets

  ssh_public_key                        = tls_private_key.ssh.private_key_pem
  cluster_endpoint_private_access_cidrs = data.terraform_remote_state.vpc_and_vpn.outputs.vpn_instances_private_ips_as_cidrs

  node_pools = {
    m5-node-pool = {
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      volume_size : 100
      subnetworks : null
      eks_target_group_arns : null
      additional_firewall_rules : {
        cidr_blocks = [
          {
            name : "Debug 1"
            type : "ingress"
            cidr_block : "0.0.0.0/0"
            protocol : "TCP"
            from_port : 80
            to_port : 80
            tags : {
              "hello" : "tag",
              "cluster-tags" : "my-value-OVERRIDE-1"
            }
          }
        ]
      }
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.24.0"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    }
    m5-node-pool-spot : {
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      spot_instance : true # optionally create spot instances
      # os : "ami-0caf35bc73450c396" # optionally define a custom AMI
      volume_size : 100
      subnetworks : null
      eks_target_group_arns : null
      additional_firewall_rules : {
        cidr_blocks = [
          {
            name : "Debug 2"
            type : "ingress"
            cidr_block : "0.0.0.0/0"
            protocol : "TCP"
            from_port : 80
            to_port : 80
            tags : {
              "hello" : "tag",
              "cluster-tags" : "my-value-OVERRIDE-2"
            }
          }
        ]
      }
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.24.0"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    },
  }

  tags = {
    Environment : "kfd-development"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
