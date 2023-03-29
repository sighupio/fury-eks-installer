output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpn_instances_private_ips" {
  value = module.vpn.vpn_instances_private_ips
}

output "vpn_instances_private_ips_as_cidrs" {
  value = [for ip in module.vpn.vpn_instances_private_ips: "${ip}/32"]
}