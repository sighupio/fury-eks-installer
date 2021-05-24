# AWS VPC and VPN

## Providers

| Name     | Version |
| -------- | ------- |
| aws      | 3.19.0  |
| external | 2.0     |
| local    | 2.0     |
| null     | 3.0     |

## Inputs

| Name                     | Description                                                     | Type           | Default                                | Required |
| ------------------------ | --------------------------------------------------------------- | -------------- | -------------------------------------- | :------: |
| name                     | Name of the resources. Used as cluster name                     | `string`       | n/a                                    |   yes    |
| network_cidr             | VPC Network CIDR                                                | `string`       | n/a                                    |   yes    |
| private_subnetwork_cidrs | Private subnet CIDRs                                            | `list(string)` | n/a                                    |   yes    |
| public_subnetwork_cidrs  | Public subnet CIDRs                                             | `list(string)` | n/a                                    |   yes    |
| vpn_ssh_users            | GitHub users id to sync public rsa keys. Example angelbarrera92 | `list(string)` | n/a                                    |   yes    |
| vpn_subnetwork_cidr      | VPN Subnet CIDR, should be different from the network_cidr      | `string`       | n/a                                    |   yes    |
| tags                     | A map of tags to add to all resources                           | `map(string)`  | `{}`                                   |    no    |
| vpn_dhparams_bits        | Diffie–Hellman (D-H) key size in bytes                          | `number`       | `2048`                                 |    no    |
| vpn_instance_disk_size   | VPN main disk size                                              | `number`       | `50`                                   |    no    |
| vpn_instance_type        | EC2 instance type                                               | `string`       | `"t3.micro"`                           |    no    |
| vpn_operator_cidrs       | VPN Operator cidrs. Used to log into the instance via SSH       | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]<br></pre> |    no    |
| vpn_operator_name        | VPN operator name. Used to log into the instance via SSH        | `string`       | `"sighup"`                             |    no    |
| vpn_port                 | VPN Server Port                                                 | `number`       | `1194`                                 |    no    |

## Outputs

| Name                        | Description                                                                     |
| --------------------------- | ------------------------------------------------------------------------------- |
| furyagent                   | furyagent.yml used by the vpn instance and ready to use to create a vpn profile |
| private_subnets             | List of IDs of private subnets                                                  |
| private_subnets_cidr_blocks | List of cidr_blocks of private subnets                                          |
| public_subnets              | List of IDs of public subnets                                                   |
| public_subnets_cidr_blocks  | List of cidr_blocks of public subnets                                           |
| vpc_cidr_block              | The CIDR block of the VPC                                                       |
| vpc_id                      | The ID of the VPC                                                               |
| vpn_ip                      | VPN instance IP                                                                 |
