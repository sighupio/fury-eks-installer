locals {
  os              = data.external.os.result.os
  arch            = data.external.os.result.arch
  local_furyagent = "${path.module}/bin/furyagent-${lower(local.os)}-${lower(local.arch)}"

  vpc_cidr_block = data.aws_vpc.this.cidr_block

  vpntemplate_vars = {
    openvpn_port           = var.vpn_port,
    openvpn_subnet_network = cidrhost(var.vpn_subnetwork_cidr, 0),
    openvpn_subnet_netmask = cidrnetmask(var.vpn_subnetwork_cidr),
    openvpn_routes = coalesce(
      var.vpn_routes,
      [
        {
          "network" : cidrhost(local.vpc_cidr_block, 0),
          "netmask" : cidrnetmask(local.vpc_cidr_block)
        }
      ]
    ),
    openvpn_dns_servers  = [cidrhost(local.vpc_cidr_block, 2)], # The second ip is the DNS in AWS
    openvpn_dhparam_bits = var.vpn_dhparams_bits,
    furyagent_version    = "v0.2.2"
    furyagent            = indent(6, local_file.furyagent.content),
  }

  furyagent_vars = {
    bucketName     = aws_s3_bucket.furyagent.bucket,
    aws_access_key = aws_iam_access_key.furyagent.id,
    aws_secret_key = aws_iam_access_key.furyagent.secret,
    region         = data.aws_region.current.name,
    servers        = [for serverIP in aws_eip.vpn.*.public_ip : "${serverIP}:${var.vpn_port}"]
    user           = var.vpn_operator_name,
  }
  furyagent = templatefile("${path.module}/templates/furyagent.yml", local.furyagent_vars)
  users     = var.vpn_ssh_users
  sshkeys_vars = {
    users = local.users
  }
  sshkeys = templatefile("${path.module}/templates/ssh-users.yml", local.sshkeys_vars)
}
