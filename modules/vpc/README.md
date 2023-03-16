<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - vpc-and-vpn module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | ~> 3.76 |
| external | ~> 2.3 |
| local | ~> 2.4 |
| null | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.76 |
| external | ~> 2.3 |
| local | ~> 2.4 |
| null | ~> 3.2 |

## Inputs

| Name                       | Description                                                     | Default               | Required |
| -------------------------- | --------------------------------------------------------------- | --------------------- | :------: |
| name                       | Name of the resources. Used as cluster name                     | n/a                   |   yes    |
| network\_cidr              | VPC Network CIDR                                                | n/a                   |   yes    |
| private\_subnetwork\_cidrs | Private subnet CIDRs                                            | n/a                   |   yes    |
| public\_subnetwork\_cidrs  | Public subnet CIDRs                                             | n/a                   |   yes    |
| tags                       | A map of tags to add to all resources                           | `{}`                  |    no    |

## Outputs

| Name                           | Description                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------- |
| private\_subnets               | List of IDs of private subnets                                                  |
| private\_subnets\_cidr\_blocks | List of cidr\_blocks of private subnets                                         |
| public\_subnets                | List of IDs of public subnets                                                   |
| public\_subnets\_cidr\_blocks  | List of cidr\_blocks of public subnets                                          |
| vpc\_cidr\_block               | The CIDR block of the VPC                                                       |
| vpc\_id                        | The ID of the VPC                                                               |


## Usage

See the [examples](../../examples) directory for examples of how to use this module.

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
