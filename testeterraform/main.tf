terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# CHAMA O MÓDULO
# Aqui está a mágica. Todo o código que tínhamos foi para cá.
module "meu_cluster_eks" {
  source = "./modules" # Caminho para o módulo local

  # --- Entradas (Inputs) ---
  # Passamos as variáveis para o módulo
  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  # Podemos sobrescrever os padrões do módulo se quisermos
  # instance_type    = "t3.medium" 
  # node_desired_size = 3
}