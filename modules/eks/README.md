# Fury EKS Installer

## Providers

| Name       | Version   |
| ---------- | --------- |
| aws        | >= 2.52.0 |
| kubernetes | >= 1.11.1 |

## Inputs

| Name             | Description                                                                                     | Type                                                                                                                                                                                                                                                                                       | Default | Required |
| ---------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------- | :------: |
| cluster\_name    | Cluster Name. Used in multiple resources to identify your cluster resources                     | `string`                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| cluster\_version | Kubernetes Cluster Version                                                                      | `string`                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| dmz\_cidr\_range | Network CIDR range from where cluster control plane will be accessible                          | `string`                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| network          | VPC ID where EKS will be hosted                                                                 | `string`                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| node\_pools      | An object list defining worker group configurations to be defined                               | <pre>list(object({<br>    name          = string<br>    version       = string # null to use cluster_version<br>    min_size      = number<br>    max_size      = number<br>    instance_type = string<br>    volume_size   = number<br>    labels        = map(string)<br>  }))<br></pre> | `[]`    |    no    |
| ssh\_public\_key | Cluster administrator public ssh key. Used to access cluster nodes with the operator\_ssh\_user | `string`                                                                                                                                                                                                                                                                                   | n/a     |   yes    |
| subnetworks      | List of subnets where EKS will be hosted                                                        | `list`                                                                                                                                                                                                                                                                                     | n/a     |   yes    |

## Outputs

| Name                            | Description                                                                                                                                                               |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cluster\_certificate\_authority | The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster |
| cluster\_endpoint               | The endpoint for your Kubernetes API server                                                                                                                               |
| operator\_ssh\_user             | SSH user to access cluster nodes with ssh\_public\_key                                                                                                                    |

