output "furyagent" {
  description = "furyagent.yml used by the VPN instance and ready to use to create a VPN profile"
  sensitive   = true
  value       = local.furyagent
}

output "vpn_ip" {
  description = "VPN instance IP"
  value       = aws_eip.vpn.*.public_ip
}

output "vpn_instances_private_ips" {
  value = [for instance in aws_instance.vpn : instance.private_ip]
}

output "vpn_instances_private_ips_as_cidrs" {
  value = [for instance in aws_instance.vpn : "${instance.private_ip}/32"]
}
