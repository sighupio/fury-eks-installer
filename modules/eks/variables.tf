variable "availability_zone_names" {
  description = "A list of availability zones names in the region"
  type        = list(string)
  default     = []
}

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

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cluster_log_retention_days)
    error_message = "Log retention is not valid. Valid values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, and 3653."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Kubernetes cluster will be hosted"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets where the cluster will be hosted"
}

variable "ssh_public_key" {
  type        = string
  description = "Cluster administrator public ssh key. Used to access cluster nodes with the operator_ssh_user"
}

variable "node_pools" {
  description = "An object list defining node pools configurations"
  type = list(object({
    name              = string
    ami_id            = optional(string)
    version           = optional(string) # null to use cluster_version
    min_size          = number
    max_size          = number
    instance_type     = string
    container_runtime = optional(string)
    spot_instance     = optional(bool)
    max_pods          = optional(number) # null to use default upstream configuration
    volume_size       = number
    subnets           = optional(list(string)) # null to use default upstream configuration
    labels            = optional(map(string))
    taints            = optional(list(string))
    tags              = optional(map(string))
    target_group_arns = optional(list(string))
    additional_firewall_rules = optional(
      object({
        cidr_blocks = optional(
          list(
            object({
              name        = string
              type        = string
              cidr_blocks = list(string)
              protocol    = string
              from_port   = number
              to_port     = number
              tags        = map(string)
            })
          )
        )
        source_security_group_id = optional(
          list(
            object({
              name                     = string
              type                     = string
              source_security_group_id = string
              protocol                 = string
              from_port                = number
              to_port                  = number
              tags                     = map(string)
            })
          )
        )
        self = optional(
          list(
            object({
              name      = string
              type      = string
              self      = bool
              protocol  = string
              from_port = number
              to_port   = number
              tags      = map(string)
            })
          )
        )
      })
    )
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
  type        = map(string)
  description = "The tags to apply to all resources"
  default     = {}
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

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_to_nodes_allowed_cidr_blocks" {
  description = "List of CIDR blocks which can access via SSH the Amazon EKS nodes"
  type        = list(string)
  default     = null
}