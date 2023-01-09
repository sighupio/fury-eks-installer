output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = data.aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster"
  value       = data.aws_eks_cluster.cluster.certificate_authority.0.data
}

output "operator_ssh_user" {
  description = "SSH user to access cluster nodes with ssh_public_key"
  value       = "ec2-user" # Default
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.cluster.cluster_oidc_issuer_url
}

output "eks_cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.cluster.oidc_provider_arn
}

output "eks_worker_iam_role_name" {
  description = "Default IAM role name for EKS worker groups"
  value       = module.cluster.worker_iam_role_name
}

output "eks_workers_asg_names" {
  description = "Names of the autoscaling groups containing workers."
  value       = module.cluster.workers_asg_names
}

output "eks_cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console."
  value = module.cluster.cluster_primary_security_group_id
}

output "eks_worker_security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = module.cluster.worker_security_group_id
}

output "eks_worker_additional_security_group_id" {
  description = "Additional security group ID attached to EKS workers."
  value       = aws_security_group.nodes.id
}