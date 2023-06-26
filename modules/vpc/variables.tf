variable "name" {
  description = "VPC Name"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  validation {
    condition     = parseint(split("/", var.cidr)[1], 10) >= 16
    error_message = "VPC CIDR can not be larger than /16."
  }
  validation {
    condition     = parseint(split("/", var.cidr)[1], 10) <= 28
    error_message = "VPC CIDR can not be smaller than /28."
  }
}

variable "extra_ipv4_cidr_blocks" {
  description = "VPC extra CIDRs"
  type        = list(string)
  validation {
    condition     = length(var.extra_ipv4_cidr_blocks) <= 4
    error_message = "AWS VPC support only 4 extra CIDR block."
  }
  validation {
    condition = alltrue(flatten([
      for cidr in var.extra_ipv4_cidr_blocks :
      (parseint(split("/", cidr)[1], 10) >= 16)
    ]))
    error_message = "VPC extra CIDR can not be larger than /16."
  }
  validation {
    condition = alltrue(flatten([
      for cidr in var.extra_ipv4_cidr_blocks :
      (parseint(split("/", cidr)[1], 10) <= 28)
    ]))
    error_message = "VPC extra CIDR can not be smaller than /28."
  }

  default = []
}

variable "availability_zone_names" {
  description = "A list of availability zones names in the region"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.aws_availability_zone_names` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.aws_availability_zone_names`."
  type        = bool
  default     = true
}

variable "private_subnetwork_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "public_subnetwork_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "names_of_kubernetes_cluster_integrated_with_subnets" {
  description = "Name of kubernetes cluster that will use ELB subnet integration via tags"
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
