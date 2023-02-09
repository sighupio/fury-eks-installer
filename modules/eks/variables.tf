variable "cluster_name" {
  type        = string
  description = "Unique cluster name. Used in multiple resources to identify your cluster resources"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes Cluster Version. Look at the cloud providers documentation to discover available versions. EKS example -> 1.16, GKE example -> 1.16.8-gke.9"
}

variable "cluster_log_retention_days" {
  type        = number
  default     = 90
  description = "Kubernetes Cluster log retention in days. Defaults to 90 days."
}

variable "network" {
  type        = string
  description = "Network where the Kubernetes cluster will be hosted"
}

variable "subnetworks" {
  type        = list(any)
  description = "List of subnets where the cluster will be hosted"
}

variable "dmz_cidr_range" {
  description = "Network CIDR range from where cluster control plane will be accessible"
}

locals {
  parsed_dmz_cidr_range = flatten([var.dmz_cidr_range])
}

variable "ssh_public_key" {
  type        = string
  description = "Cluster administrator public ssh key. Used to access cluster nodes with the operator_ssh_user"
}

variable "node_pools" {
  description = "An object list defining node pools configurations"
  type = list(object({
    name                  = string
    version               = string # null to use cluster_version
    min_size              = number
    max_size              = number
    instance_type         = string
    os                    = optional(string)
    container_runtime     = optional(string)
    spot_instance         = optional(bool)
    max_pods              = optional(number) # null to use default upstream configuration
    volume_size           = number
    subnetworks           = list(string) # null to use default upstream configuration
    labels                = map(string)
    taints                = list(string)
    tags                  = map(string)
    eks_target_group_arns = optional(list(string))
    additional_firewall_rules = list(object({
      name       = string
      direction  = string
      cidr_block = string
      protocol   = string
      ports      = string
      tags       = map(string)
    }))
  }))
  default = []
}

variable "node_pools_launch_kind" {
  description = "Which kind of node pools to create. Valid values are: launch_templates, launch_configurations, both."
  type        = string
  default     = "launch_templates"

  validation {
    condition     = length(regexall("^(launch_templates|launch_configurations|both)$", var.node_pools_launch_kind)) > 0
    error_message = "ERROR: Valid values are \"launch_templates\", \"launch_configurations\" and \"both\"!"
  }
}

variable "tags" {
  type        = map(any)
  description = "The tags to apply to all resources"
  default     = {}
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where every resource will be placed. Required only in AKS installer (*)"
  default     = ""
}

variable "eks_map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap"
  type        = list(string)

  # example = [
  #   "777777777777",
  #   "888888888888",
  # ]
}

variable "eks_map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  # example = [
  #   {
  #     rolearn  = "arn:aws:iam::66666666666:role/role1"
  #     username = "role1"
  #     groups   = ["system:masters"]
  #   },
  # ]
}

variable "eks_map_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  # example = [
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user1"
  #     username = "user1"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user2"
  #     username = "user2"
  #     groups   = ["system:masters"]
  #   },
  # ]
}
