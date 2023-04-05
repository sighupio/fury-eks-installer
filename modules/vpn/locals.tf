locals {
  os              = data.external.os.result.os
  local_furyagent = local.os == "Darwin" ? "${path.module}/bin/furyagent-darwin-amd64" : "${path.module}/bin/furyagent-linux-amd64"

  vpc_cidr_block = data.aws_vpc.this.cidr_block

  # https://cloud-images.ubuntu.com/locator/ec2/
  # filter: 20.04 LTS eu- ebs-ssd 2020 amd64
  ubuntu_amis = {
    us-west-1      = "ami-081a3b9eded47f0f3"
    eu-north-1     = "ami-0cf13cb849b11b451"
    ap-northeast-1 = "ami-0d0c6a887ce442603"
    sa-east-1      = "ami-002a875adefcee7fc"
    eu-south-1     = "ami-035b0582f3881e4b3"
    af-south-1     = "ami-043ae129b84099da5"
    us-east-1      = "ami-0aa2b7722dc1b5612"
    eu-central-1   = "ami-0d497a49e7d359666"
    ap-south-1     = "ami-03a933af70fa97ad2"
    ap-southeast-1 = "ami-062550af7b9fa7d05"
    me-south-1     = "ami-0f11b4602adfe829d"
    ap-east-1      = "ami-0d7ce860e738db09b"
    eu-west-1      = "ami-05147510eb2885c80"
    me-central-1   = "ami-090c2cd544ddaa64d"
    ca-central-1   = "ami-01c7ecac079939e18"
    eu-south-2     = "ami-0d799a52a88d01cd3"
    ap-southeast-2 = "ami-03d0155c1ef44f68a"
    ap-south-2     = "ami-060a418af37852e64"
    eu-central-2   = "ami-04fe12af5cb123aec"
    ap-northeast-2 = "ami-0c6e5afdd23291f73"
    us-west-2      = "ami-0db245b76e5c21ca1"
    us-east-2      = "ami-06c4532923d4ba1ec"
    eu-west-2      = "ami-028a5cd4ffd2ee495"
    ap-northeast-3 = "ami-07a129a553165490c"
    eu-west-3      = "ami-01a3ab628b8168507"
    ap-southeast-3 = "ami-0818b5dc03ada5b9b"
    ap-southeast-4 = "ami-0e84609f20e8e1201"
  }

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
