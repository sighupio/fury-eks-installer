<!-- BEGIN_TF_DOCS -->

# Fury EKS Installer - vpn module

<!-- <KFD-DOCS> -->

## Requirements

| Name | Version   |
|------|-----------|
| terraform | `>= 1.3.0`  |

## Providers

| Name | Version   |
|------|-----------|
| aws | `3.56.0`    |
| external | `~>2.1.1` |
| local | `~>2.1.0` |
| null | `3.1.1`   |

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| name | Name of the resources. Used as cluster name | n/a | yes |
| public\_subnets | List of IDs of public subnets | `[]` | no |
| tags | A map of tags to add to all resources | `{}` | no |
| vpc\_id | The ID of the VPC | n/a | yes |
| vpn\_dhparams\_bits | Diffie-Hellman (D-H) key size in bytes | `2048` | no |
| vpn\_instance\_disk\_size | VPN main disk size | `50` | no |
| vpn\_instance\_type | EC2 instance type | `"t3.micro"` | no |
| vpn\_instances | number of VPN Servers (bastions) to create | `1` | no |
| vpn\_operator\_cidrs | List of CIDRs allowed to log into the instance via SSH | ```[ "0.0.0.0/0" ]``` | no |
| vpn\_operator\_name | VPN operator name. Used to log into the instance via SSH | `"sighup"` | no |
| vpn\_port | OpenVPN Server listening port | `1194` | no |
| vpn\_routes | VPN routes | `[]` | no |
| vpn\_ssh\_users | GitHub users id to sync public rsa keys. Example angelbarrera92 | `[]` | no |
| vpn\_subnetwork\_cidr | CIDR used to assign VPN clients IP addresses, should be different from the network\_cidr | n/a | yes |

## Outputs

| Name                                    | Description                                                                     |
|-----------------------------------------|---------------------------------------------------------------------------------|
| furyagent                               | furyagent.yml used by the VPN instance and ready to use to create a VPN profile |
| vpn\_ip                                 | VPN instance public IPs                                                         |
| vpn\_instances\_private\_ips            | VPN instance private IPs                                                        |
| vpn\_instances\_private\_ips\_as\_cidrs | VPN instance private IPs as CIDR blocks                                         |
| aws\_iam\_user\_arn                     | furyagent AWS IAM User ARN                                                      |
| aws\_iam\_policy\_arn                   | furyagent AWS IAM Policy ARN                                                    |

## Usage

```hcl
/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = "~> 0.15"
  required_providers {
    local    = "~> 2.0.0"
    null     = "~> 3.0.0"
    aws      = "~> 3.56.0"
    external = "~> 2.0.0"
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "vpn" {
  source = "../../modules/vpn"

  count = 1

  name = "fury"
  tags = {
    "environment" = "example"
  }

  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets

  vpn_subnetwork_cidr = "192.168.200.0/24"
  vpn_ssh_users       = ["github-user"]
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
