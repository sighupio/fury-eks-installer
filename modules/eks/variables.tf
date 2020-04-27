variable "cluster_name" {
  type        = string
  description = "Cluster Name. Used in multiple resources to identify your cluster resources"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes Cluster Version"
}
variable "network" {
  type        = string
  description = "VPC ID where EKS will be hosted"
}

variable "subnetworks" {
  type        = list
  description = "List of subnets where EKS will be hosted"
}

variable "dmz_cidr_range" {
  type        = string
  description = "Network CIDR range from where cluster control plane will be accessible"
}

variable "ssh_public_key" {
  type        = string
  description = "Cluster administrator public ssh key. Used to access cluster nodes with the operator_ssh_user"
}

variable "node_pools" {
  description = "An object list defining worker group configurations to be defined"
  type = list(object({
    name          = string
    version       = string # null to use cluster_version
    min_size      = number
    max_size      = number
    instance_type = string
    volume_size   = number
    labels        = map(string)
  }))
  default = []
}
