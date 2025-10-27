output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.meu_cluster_eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do EKS (API server)."
  value       = module.meu_cluster_eks.cluster_endpoint
}