output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do EKS (API server)."
  value       = aws_eks_cluster.eks_cluster.endpoint
}