variable "cluster_name" {
  description = "O nome principal para o cluster EKS e recursos."
  type        = string
  default     = "meu-cluster-minimo"
}

variable "aws_region" {
  description = "Região da AWS para provisionar os recursos."
  type        = string
  default     = "us-east-1"
}