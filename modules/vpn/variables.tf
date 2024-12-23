variable "name" {
  description = "Name of the resources. Used as cluster name"
  type        = string
}

variable "public_subnets" {
  description = "List of IDs of public subnets"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpn_dhparams_bits" {
  description = "Diffie-Hellman (D-H) key size in bytes"
  type        = number
  default     = 2048
}

variable "vpn_instance_disk_size" {
  description = "VPN main disk size"
  type        = number
  default     = 50
}

variable "vpn_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpn_instances" {
  description = "number of VPN Servers (bastions) to create"
  type        = number
  default     = 1
}

variable "vpn_operator_cidrs" {
  description = "List of CIDRs allowed to log into the instance via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_operator_name" {
  description = "VPN operator name. Used to log into the instance via SSH"
  type        = string
  default     = "sighup"
}

variable "vpn_port" {
  description = "OpenVPN Server listening port"
  type        = number
  default     = 1194
}

variable "vpn_ssh_users" {
  description = "GitHub users id to sync public rsa keys. Example jnardiello"
  type        = list(string)
  default     = []
}

variable "vpn_subnetwork_cidr" {
  description = "CIDR used to assign VPN clients IP addresses, should be different from the network_cidr"
  type        = string
}

variable "vpn_routes" {
  description = "VPN routes"
  type = list(object({
    network = string
    netmask = string
  }))
  default = null
}

variable "vpn_bucket_name_prefix" {
  type        = string
  description = "Bucket name prefix for VPN configuration files"
  default     = ""
}

variable "vpn_iam_user_name_override" {
  type        = string
  description = "Override the name of the IAM user, if not set it will use the cluster name"
  default     = ""
}
