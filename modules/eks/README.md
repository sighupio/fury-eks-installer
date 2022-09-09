<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - EKS module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version |
|------|---------|
| terraform | 1.2.9 |
| aws | 3.37.0 |
| kubernetes | 1.13.3 |

## Providers

| Name | Version |
|------|---------|
| aws | 3.37.0 |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| cluster\_name | Unique cluster name. Used in multiple resources to identify your cluster resources | n/a | yes |
| cluster\_version | Kubernetes Cluster Version. Look at the cloud providers documentation to discover available versions. EKS example -> 1.16, GKE example -> 1.16.8-gke.9 | n/a | yes |
| dmz\_cidr\_range | Network CIDR range from where cluster control plane will be accessible | n/a | yes |
| eks\_map\_accounts | Additional AWS account numbers to add to the aws-auth configmap | n/a | yes |
| eks\_map\_roles | Additional IAM roles to add to the aws-auth configmap | n/a | yes |
| eks\_map\_users | Additional IAM users to add to the aws-auth configmap | n/a | yes |
| network | Network where the Kubernetes cluster will be hosted | n/a | yes |
| node\_pools | An object list defining node pools configurations | `[]` | no |
| resource\_group\_name | Resource group name where every resource will be placed. Required only in AKS installer (*) | `""` | no |
| ssh\_public\_key | Cluster administrator public ssh key. Used to access cluster nodes with the operator\_ssh\_user | n/a | yes |
| subnetworks | List of subnets where the cluster will be hosted | n/a | yes |
| tags | The tags to apply to all resources | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_certificate\_authority | The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster |
| cluster\_endpoint | The endpoint for your Kubernetes API server |
| eks\_cluster\_oidc\_issuer\_url | The URL on the EKS cluster OIDC Issuer |
| eks\_worker\_iam\_role\_name | Default IAM role name for EKS worker groups |
| eks\_worker\_security\_group\_id | Security group ID attached to the EKS workers. |
| eks\_workers\_asg\_names | Names of the autoscaling groups containing workers. |
| operator\_ssh\_user | SSH user to access cluster nodes with ssh\_public\_key |

## Usage

See the [example folder](example/eks) for an overview on how to use this module.

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
