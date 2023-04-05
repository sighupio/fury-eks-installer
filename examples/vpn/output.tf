output "vpn_instances_private_ips" {
  value = module.vpn.vpn_instances_private_ips
}

output "vpn_instances_private_ips_as_cidrs" {
  value = [for ip in module.vpn.vpn_instances_private_ips: "${ip}/32"]
}