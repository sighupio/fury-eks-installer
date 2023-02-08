output "vpc_id" {
  value = module.vpc_and_vpn.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc_and_vpn.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc_and_vpn.private_subnets
}
