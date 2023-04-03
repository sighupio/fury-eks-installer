<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - vpc module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15.4 |
| aws | 3.56.0 |
| external | 2.0.0 |
| local | 2.0.0 |
| null | 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | 3.56.0 |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| name | Will be used as a prefix for resource names. The cluster name must be the same | n/a | yes |
| network\_cidr | VPC Network CIDR | n/a | yes |
| private\_subnetwork\_cidrs | Private subnet CIDRs | n/a | yes |
| public\_subnetwork\_cidrs | Public subnet CIDRs | n/a | yes |
| tags | A map of tags to add to all resources | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| private\_subnets | List of IDs of private subnets |
| private\_subnets\_cidr\_blocks | List of cidr\_blocks of private subnets |
| public\_subnets | List of IDs of public subnets |
| public\_subnets\_cidr\_blocks | List of cidr\_blocks of public subnets |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_id | The ID of the VPC |

## Usage

```hcl
/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = ">=0.15.4"
  required_providers {
    local    = "2.0.0"
    null     = "3.0.0"
    aws      = "3.56.0"
    external = "2.0.0"
  }
}

module "vpc" {
    source = "../../modules/vpc"

    name = "fury"
    network_cidr = "10.0.0.0/16"
    tags = {
      "environment" = "example"
    }

    public_subnetwork_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnetwork_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "vpn" {
    source = "../../modules/vpn"

    count = 1

    name = "fury"
    network_cidr = "10.0.0.0/16"
    tags = {
      "environment" = "example"
    }

    vpc_id = module.vpc.vpc_id
    public_subnets = module.vpc.public_subnets

    vpn_subnetwork_cidr = "192.168.200.0/24"
    vpn_ssh_users = ["github-user"]
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
