output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = data.aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster"
  value       = data.aws_eks_cluster.cluster.certificate_authority.0.data
}
