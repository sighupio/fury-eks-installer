/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = "~> 0.15"
  required_providers {
    aws      = "~> 3.56.0"
    external = "~> 2.0.0"
    local    = "~> 2.0.0"
    null     = "~> 3.0.0"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "${path.root}/../vpc/terraform.tfstate"
  }
}

module "vpn" {
  source = "../../modules/vpn"

  name = "fury"
  tags = {
    "environment" = "example"
  }

  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets = data.terraform_remote_state.vpc.outputs.public_subnets

  vpn_subnetwork_cidr = "192.168.200.0/24"
  vpn_ssh_users       = ["github-user"]
}
