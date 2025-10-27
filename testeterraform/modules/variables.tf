variable "cluster_name" {
  description = "Nome a ser usado para o cluster EKS."
  type        = string
}

variable "aws_region" {
  description = "Região da AWS."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a nova VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "Lista de blocos CIDR para as sub-redes públicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "Tipo de instância EC2 para os nós."
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Número de nós desejado."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nós."
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Número mínimo de nós."
  type        = number
  default     = 1
}