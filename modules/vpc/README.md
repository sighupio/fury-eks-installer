<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - vpc module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.3  |
| aws | ~> 3.76 |
| external | ~> 2.3  |
| local | ~> 2.4  |
| null | ~> 3.2  |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.76 |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| availability\_zone\_names | A list of availability zones names in the region | `[]` | no |
| cidr | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden | n/a | yes |
| extra\_ipv4\_cidr\_blocks | VPC extra CIDRs | `[]` | no |
| name | VPC Name | n/a | yes |
| names\_of\_kubernetes\_cluster\_integrated\_with\_subnets | Name of kubernetes cluster that will use ELB subnet integration via tags | `[]` | no |
| one\_nat\_gateway\_per\_az | Should be true if you want only one NAT Gateway per availability zone. Requires `var.aws_availability_zone_names` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.aws_availability_zone_names`. | `true` | no |
| private\_subnetwork\_cidrs | Private subnet CIDRs | n/a | yes |
| public\_subnetwork\_cidrs | Public subnet CIDRs | n/a | yes |
| single\_nat\_gateway | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `false` | no |
| tags | A map of tags to add to all resources | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| nat\_public\_ips | n/a |
| private\_subnets | List of IDs of private subnets |
| private\_subnets\_cidr\_blocks | List of cidr\_blocks of private subnets |
| public\_subnets | List of IDs of public subnets |
| public\_subnets\_cidr\_blocks | List of cidr\_blocks of public subnets |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_id | The ID of the VPC |
| vpc\_ipv4\_extra\_cidr\_blocks | The extra CIDR block of the VPC |

## Usage

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

module "vpc" {
  source = "../../modules/vpc"

  name = "fury"
  cidr = "10.0.0.0/16"
  tags = {
    "environment" = "example"
  }

  #  one_nat_gateway_per_az = true
  single_nat_gateway = true

  public_subnetwork_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnetwork_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  names_of_kubernetes_cluster_integrated_with_subnets = [
    "fury-private-example",
    "fury-public-example"
  ]
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->