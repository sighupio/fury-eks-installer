variable "cluster_name" {
  type        = string
  default     = "fury-example"
  description = "Unique cluster name. Used in multiple resources to identify your cluster resources"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to be used to access the cluster nodes"
}
