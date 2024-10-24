/**
 * Copyright (c) 2017-present SIGHUP s.r.l All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

terraform {
  required_version = "~> 1.4.6"
  required_providers {
    local    = "~> 2.4.0"
    null     = "~> 3.2.1"
    aws      = "~> 5.22.0"
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
