output "token_cmd" {
  value = "aws-iam-authenticator token -i ${local.cluster_name} --token-only"
}

output "kubeconfig_filename" {
  value = "export KUBECONFIG=${module.eks-cluster.kubeconfig_filename}"
}
