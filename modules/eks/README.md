<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - EKS module

<!-- <KFD-DOCS> -->

## Requirements

| Name       | Version |
| ---------- | ------- |
| terraform  | 0.15.4  |
| aws        | 3.56.0  |
| kubernetes | 1.13.3  |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | 3.56.0  |

## Inputs

| Name                                      | Description                                                                                                                                            | Default              | Required |
|-------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------|:--------:|
| cluster\_endpoint\_private\_access        | Indicates whether or not the Amazon EKS private API server endpoint is enabled.                                                                        | `true`               |    no    |
| cluster\_endpoint\_private\_access\_cidrs | List of CIDR blocks which can access the Amazon EKS private API server endpoint.                                                                       | `["10.0.0.0/16"]`    |    no    |
| cluster\_endpoint\_public\_access         | Indicates whether or not the Amazon EKS public API server endpoint is enabled.                                                                         | `false`              |    no    |
| cluster\_endpoint\_public\_access\_cidrs  | List of CIDR blocks which can access the Amazon EKS public API server endpoint.                                                                        | `["0.0.0.0/0"]`      |    no    |
| cluster\_log\_retention\_days             | Kubernetes Cluster log retention in days. Defaults to 90 days.                                                                                         | `90`                 |    no    |
| cluster\_name                             | Unique cluster name. Used in multiple resources to identify your cluster resources                                                                     | n/a                  |   yes    |
| cluster\_version                          | Kubernetes Cluster Version. Look at the cloud providers documentation to discover available versions. EKS example -> 1.16, GKE example -> 1.16.8-gke.9 | n/a                  |   yes    |
| eks\_map\_accounts                        | Additional AWS account numbers to add to the aws-auth configmap                                                                                        | n/a                  |   yes    |
| eks\_map\_roles                           | Additional IAM roles to add to the aws-auth configmap                                                                                                  | n/a                  |   yes    |
| eks\_map\_users                           | Additional IAM users to add to the aws-auth configmap                                                                                                  | n/a                  |   yes    |
| network                                   | Network where the Kubernetes cluster will be hosted                                                                                                    | n/a                  |   yes    |
| node\_pools                               | An object list defining node pools configurations                                                                                                      | `[]`                 |    no    |
| node\_pools\_launch\_kind                 | Which kind of node pools to create. Valid values are: launch\_templates, launch\_configurations, both.                                                 | `"launch_templates"` |    no    |
| resource\_group\_name                     | Resource group name where every resource will be placed. Required only in AKS installer (*)                                                            | `""`                 |    no    |
| ssh\_public\_key                          | Cluster administrator public ssh key. Used to access cluster nodes with the operator\_ssh\_user                                                        | n/a                  |   yes    |
| subnetworks                               | List of subnets where the cluster will be hosted                                                                                                       | n/a                  |   yes    |
| tags                                      | The tags to apply to all resources                                                                                                                     | `{}`                 |    no    |

## Outputs

| Name                                         | Description                                                                                                                                                               |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cluster\_certificate\_authority              | The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster |
| cluster\_endpoint                            | The endpoint for your Kubernetes API server                                                                                                                               |
| eks\_cluster\_oidc\_issuer\_url              | The URL on the EKS cluster OIDC Issuer                                                                                                                                    |
| eks\_cluster\_oidc\_provider\_arn            | The ARN of the OIDC Provider                                                                                                                                              |
| eks\_cluster\_primary\_security\_group\_id   | The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console.                            |
| eks\_worker\_additional\_security\_group\_id | Additional security group ID attached to EKS workers.                                                                                                                     |
| eks\_worker\_iam\_role\_name                 | Default IAM role name for EKS worker groups                                                                                                                               |
| eks\_worker\_security\_group\_id             | Security group ID attached to the EKS workers.                                                                                                                            |
| eks\_workers\_asg\_names                     | Names of the autoscaling groups containing workers.                                                                                                                       |
| operator\_ssh\_user                          | SSH user to access cluster nodes with ssh\_public\_key                                                                                                                    |

## Usage

```hcl
data "terraform_remote_state" "vpc_and_vpn" {
  backend = "local"
  config = {
    path = "${path.module}/../vpc-and-vpn/terraform.tfstate"
  }
}

module "fury_example" {
  source = "../../modules/eks"

  cluster_name    = "fury-example"
  cluster_version = "1.24"

  network     = data.terraform_remote_state.vpc_and_vpn.outputs.vpc_id
  subnetworks = data.terraform_remote_state.vpc_and_vpn.outputs.private_subnets

  ssh_public_key = var.ssh_public_key

  cluster_endpoint_private_access = true
  cluster_endpoint_private_access_cidrs = ["10.0.0.0/16"]

  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = ["80.253.32.0/20"]

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
            "cluster-tags" : "my-value-OVERRIDE-1"
          }
        }
      ]
      labels : {
        "node.kubernetes.io/role" : "app"
        "sighup.io/fury-release" : "v1.24.0"
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
      # os : "ami-0caf35bc73450c396" # optionally define a custom AMI
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
        "sighup.io/fury-release" : "v1.24.0"
      }
      taints : []
      tags : {
        "node-tags" : "exists"
      }
      # max_pods : null # To use default EKS setting set it to null or do not set it
    },
  ]

  tags = {
    Environment: "kfd-development"
  }

  eks_map_users    = []
  eks_map_roles    = []
  eks_map_accounts = []
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
