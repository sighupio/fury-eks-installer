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

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| name | Name of the resources. Used as cluster name | n/a | yes |
| network\_cidr | VPC Network CIDR | n/a | yes |
| private\_subnetwork\_cidrs | Private subnet CIDRs | n/a | yes |
| public\_subnetwork\_cidrs | Public subnet CIDRs | n/a | yes |
| tags | A map of tags to add to all resources | `{}` | no |
| vpn\_dhparams\_bits | Diffie–Hellman (D-H) key size in bytes | `2048` | no |
| vpn\_instance\_disk\_size | VPN main disk size | `50` | no |
| vpn\_instance\_type | EC2 instance type | `"t3.micro"` | no |
| vpn\_instances | VPN Servers | `1` | no |
| vpn\_operator\_cidrs | VPN Operator cidrs. Used to log into the instance via SSH | ```[ "0.0.0.0/0" ]``` | no |
| vpn\_operator\_name | VPN operator name. Used to log into the instance via SSH | `"sighup"` | no |
| vpn\_port | VPN Server Port | `1194` | no |
| vpn\_ssh\_users | GitHub users id to sync public rsa keys. Example jnardiello | n/a | yes |
| vpn\_subnetwork\_cidr | VPN Subnet CIDR, should be different from the network\_cidr | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| furyagent | furyagent.yml used by the vpn instance and ready to use to create a vpn profile |
| private\_subnets | List of IDs of private subnets |
| private\_subnets\_cidr\_blocks | List of cidr\_blocks of private subnets |
| public\_subnets | List of IDs of public subnets |
| public\_subnets\_cidr\_blocks | List of cidr\_blocks of public subnets |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_id | The ID of the VPC |
| vpn\_ip | VPN instance IP |

## Usage

```hcl
module "vpc_and_vpn" {
    source = "../../modules/vpc-and-vpn"

    name = "fury"

    network_cidr = "10.0.0.0/16"
    public_subnetwork_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnetwork_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    vpn_subnetwork_cidr = "192.168.200.0/24"
    vpn_ssh_users = ["github-user"]
}

    vpn_subnetwork_cidr = "10.0.201.0/24"
    vpn_ssh_users = var.vpn_ssh_users
}
```

<!-- </KFD-DOCS> -->
<!-- END_TF_DOCS -->
