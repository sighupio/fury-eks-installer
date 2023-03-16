variable "name" {
  description = "Will be used as a prefix for resource names. The cluster name must be the same"
  type        = string
}

variable "network_cidr" {
  description = "VPC Network CIDR"
  type        = string
}

variable "private_subnetwork_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "public_subnetwork_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
