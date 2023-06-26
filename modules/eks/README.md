<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - EKS module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.3 |
| aws | ~> 3.76 |
| kubernetes | ~> 1.13 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.76 |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| availability\_zone\_names | A list of availability zones names in the region | `[]` | no |
| cluster\_endpoint\_private\_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `true` | no |
| cluster\_endpoint\_private\_access\_cidrs | List of CIDR blocks which can access the Amazon EKS private API server endpoint | ```[ "0.0.0.0/0" ]``` | no |
| cluster\_endpoint\_public\_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `false` | no |
| cluster\_endpoint\_public\_access\_cidrs | List of CIDR blocks which can access the Amazon EKS public API server endpoint | ```[ "0.0.0.0/0" ]``` | no |
| cluster\_log\_retention\_days | Kubernetes Cluster log retention in days. Defaults to 90 days. | `90` | no |
| cluster\_name | Unique cluster name. Used in multiple resources to identify your cluster resources | n/a | yes |
| cluster\_service\_ipv4\_cidr | The CIDR block to assign Kubernetes service IP addresses from | `null` | no |
| cluster\_version | Kubernetes Cluster Version. Look at the cloud providers documentation to discover available versions. EKS example -> 1.25, GKE example -> 1.25.7-gke.1000 | n/a | yes |
| eks\_map\_accounts | Additional AWS account numbers to add to the aws-auth configmap | n/a | yes |
| eks\_map\_roles | Additional IAM roles to add to the aws-auth configmap | n/a | yes |
| eks\_map\_users | Additional IAM users to add to the aws-auth configmap | n/a | yes |
| node\_pools | An object list defining node pools configurations | `[]` | no |
| node\_pools\_launch\_kind | Which kind of node pools to create. Valid values are: launch\_templates, launch\_configurations, both. | `"launch_templates"` | no |
| ssh\_public\_key | Cluster administrator public ssh key. Used to access cluster nodes with the operator\_ssh\_user | n/a | yes |
| ssh\_to\_nodes\_allowed\_cidr\_blocks | List of CIDR blocks which can access via SSH the Amazon EKS nodes | `null` | no |
| subnets | List of subnets where the cluster will be hosted | n/a | yes |
| tags | The tags to apply to all resources | `{}` | no |
| vpc\_id | VPC ID where the Kubernetes cluster will be hosted | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_certificate\_authority | The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster |
| cluster\_endpoint | The endpoint for your Kubernetes API server |
| cluster\_id | The EKS cluster ID |
| eks\_cluster\_oidc\_issuer\_url | The URL on the EKS cluster OIDC Issuer |
| eks\_cluster\_oidc\_provider\_arn | The ARN of the OIDC Provider |
| eks\_cluster\_primary\_security\_group\_id | The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console. |
| eks\_worker\_additional\_security\_group\_id | Additional security group ID attached to EKS workers. |
| eks\_worker\_iam\_role\_name | Default IAM role name for EKS worker groups |
| eks\_worker\_security\_group\_id | Security group ID attached to the EKS workers. |
| eks\_workers\_asg\_names | Names of the autoscaling groups containing workers. |
| operator\_ssh\_user | SSH user to access cluster nodes with ssh\_public\_key |

## Usage

For clusters with private API server:
```hcl
/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = "~> 1.4"
  required_providers {
    local    = "~> 2.4.0"
    null     = "~> 3.2.1"
    aws      = "~> 3.76.1"
    external = "~> 2.3.1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.fury_private_example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.fury_private_example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.fury_private_example.token
  load_config_file       = false
}

data "aws_eks_cluster" "fury_private_example" {
  name = module.fury_private_example.cluster_id
}

data "aws_eks_cluster_auth" "fury_private_example" {
  name = module.fury_private_example.cluster_id
}

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
  rsa_bits  = 2048
}

module "fury_private_example" {
  source = "../../modules/eks"

  cluster_name               = var.cluster_name # make sure to use the same name you used in the VPC and VPN module
  cluster_version            = "1.25"
  cluster_log_retention_days = 1

  availability_zone_names = ["eu-west-1a", "eu-west-1b"]
  subnets                 = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id

  cluster_endpoint_private_access_cidrs = data.terraform_remote_state.vpn.outputs.vpn_instances_private_ips_as_cidrs

  ssh_public_key = tls_private_key.ssh.public_key_openssh

  node_pools = [
    {
      name : "m5-node-pool"
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      volume_size : 100
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
        "sighup.io/fury-release" : "v1.25.0"
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
        "sighup.io/fury-release" : "v1.25.0"
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
    {
      name : "m5-node-pool-null-config"
      ami_id : null
      version : null
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      container_runtime : null
      spot_instance : null
      max_pods : null
      volume_size : 100
      subnets : null
      labels : null
      taints : null
      tags : null
      additional_firewall_rules : null
    },
  ]

  tags = {
    Environment : "kfd-development"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
```

For clusters with public API server:
```hcl
/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = "~> 1.4"
  required_providers {
    local    = "~> 2.4.0"
    null     = "~> 3.2.1"
    aws      = "~> 3.76.1"
    external = "~> 2.3.1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.fury_public_example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.fury_public_example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.fury_public_example.token
  load_config_file       = false
}

data "aws_eks_cluster" "fury_public_example" {
  name = module.fury_public_example.cluster_id
}

data "aws_eks_cluster_auth" "fury_public_example" {
  name = module.fury_public_example.cluster_id
}

data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

module "fury_public_example" {
  source = "../../modules/eks"

  cluster_name               = var.cluster_name # make sure to use the same name you used in the VPC and VPN module
  cluster_version            = "1.25"
  cluster_log_retention_days = 1

  availability_zone_names = ["eu-west-1a", "eu-west-1b"]
  subnets                 = data.terraform_remote_state.vpc.outputs.private_subnets
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  ssh_public_key = tls_private_key.ssh.public_key_openssh

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
        "sighup.io/fury-release" : "v1.25.0"
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
        "sighup.io/fury-release" : "v1.25.0"
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
    {
      name : "m5-node-pool-null-config"
      ami_id : null
      version : null
      min_size : 1
      max_size : 2
      instance_type : "m5.large"
      container_runtime : null
      spot_instance : null
      max_pods : null
      volume_size : 100
      subnets : null
      labels : null
      taints : null
      tags : null
      additional_firewall_rules : null
    },
  ]

  tags = {
    Environment : "kfd-development"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->