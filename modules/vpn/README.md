<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - vpn module

<!-- <KFD-DOCS> -->

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| external | n/a |
| local | n/a |
| null | n/a |

## Inputs

| Name                      | Description                                                     | Default               | Required |
|---------------------------|-----------------------------------------------------------------|-----------------------|:--------:|
| name                      | Name of the resources. Used as cluster name                     | n/a                   |   yes    |
| public\_subnets           | List of IDs of the public subnets to use.                       | `[]`                  |    no    |
| tags                      | A map of tags to add to all resources                           | `{}`                  |    no    |
| vpc\_id                   | Id of the VPC to create the VPN in.                             | n/a                   |   yes    |
| vpn\_dhparams\_bits       | Diffie-Hellman (D-H) key size in bytes                          | `2048`                |    no    |
| vpn\_instance\_disk\_size | VPN main disk size                                              | `50`                  |    no    |
| vpn\_instance\_type       | EC2 instance type                                               | `"t3.micro"`          |    no    |
| vpn\_instances            | VPN Servers                                                     | `1`                   |    no    |
| vpn\_operator\_cidrs      | VPN Operator cidrs. Used to log into the instance via SSH       | ```[ "0.0.0.0/0" ]``` |    no    |
| vpn\_operator\_name       | VPN operator name. Used to log into the instance via SSH        | `"sighup"`            |    no    |
| vpn\_port                 | VPN Server Port                                                 | `1194`                |    no    |
| vpn_\routes               | VPN routes                                                      | `[]`                  |    no    |
| vpn\_ssh\_users           | GitHub users id to sync public rsa keys. Example angelbarrera92 | `[]`                  |    no    |
| vpn\_subnetwork\_cidr     | VPN Subnet CIDR, should be different from the network\_cidr     | n/a                   |   yes    |

## Outputs

| Name | Description |
|------|-------------|
| furyagent | furyagent.yml used by the VPN instance and ready to use to create a VPN profile |
| vpn\_ip | VPN instance IP |

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
