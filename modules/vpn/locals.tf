locals {
  os              = data.external.os.result.os
  local_furyagent = local.os == "Darwin" ? "${path.module}/bin/furyagent-darwin-amd64" : "${path.module}/bin/furyagent-linux-amd64"

  vpc_cidr_block = data.aws_vpc.this.cidr_block

  # https://cloud-images.ubuntu.com/locator/ec2/
  # filter: 20.04 LTS eu- ebs-ssd 2020 amd64
  ubuntu_amis = {
    "eu-west-3" : "ami-098efdd0afb686fd5"
    "eu-west-2" : "ami-099ae17a6a688b1cc"
    "eu-west-1" : "ami-048309a44dad514df"
    "eu-south-1" : "ami-0e3c0649c89ccddc9"
    "eu-north-1" : "ami-01450210d4ebb3bab"
    "eu-central-1" : "ami-09f14afb2e15caab5"
    "us-east-1" : "ami-0c4f7023847b90238"
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
