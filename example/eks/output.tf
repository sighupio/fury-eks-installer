output "kube_config" {
  sensitive = true
  value     = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: ${module.my-cluster.cluster_endpoint}
    certificate-authority-data: ${module.my-cluster.cluster_certificate_authority}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${var.cluster_name}"
EOT
}
