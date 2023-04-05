data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpn" {
  backend = "local"
  config = {
    path = "${path.module}/../vpn/terraform.tfstate"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "fury_example" {
  source = "../../modules/eks"

  cluster_name               = var.cluster_name # make sure to use the same name you used in the VPC and VPN module
  cluster_version            = "1.24"
  cluster_log_retention_days = 1

  availability_zone_names = ["eu-west-1a", "eu-west-1b"]
  subnets                 = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id

  cluster_endpoint_private_access_cidrs = data.terraform_remote_state.vpn.outputs.vpn_instances_private_ips_as_cidrs

  ssh_public_key                        = tls_private_key.ssh.private_key_pem

  node_pools = [
    {
      name : "m5-node-pool"
      version : null # To use same value as cluster_version
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      volume_size : 100
      subnets : null
      target_group_arns : null
      container_runtime = "containerd"
      additional_firewall_rules : {
        cidr_blocks = [
          {
            name : "Debug 1"
            type : "ingress"
            cidr_blocks : ["0.0.0.0/0"]
            protocol : "TCP"
            from_port : 80
            to_port : 80
            tags : {
              hello : "tag"
              cluster-tags : "my-value-OVERRIDE-1"
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
    {
      name : "m5-node-pool-spot"
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      spot_instance : true # optionally create spot instances
      # ami_id : "ami-01eb5348cab8e4902" # optionally define a custom AMI
      volume_size : 100
      container_runtime = "docker"
      additional_firewall_rules : {
        cidr_blocks = [
          {
            name : "Debug 2"
            type : "ingress"
            cidr_blocks : ["0.0.0.0/0"]
            protocol : "TCP"
            from_port : 80
            to_port : 80
            tags : {
              hello : "tag"
              cluster-tags : "my-value-OVERRIDE-2"
            }
          }
        ]
      }
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.24.0"
      }
      tags : {
        "node-tags" : "exists"
      }
      max_pods : 35
    },
    {
      name : "m5-node-pool-min-config"
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      volume_size : 10
    },
  ]

  tags = {
    Environment : "kfd-development"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
