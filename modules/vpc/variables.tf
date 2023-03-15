variable "name" {
  description = "Name of the resources. Used as cluster name"
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
