data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name = "${var.cluster_name}-vpc" # Usa a variável
  cidr = var.vpc_cidr              # Usa a variável

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnets_cidr # Usa a variável
  private_subnets = []

  enable_nat_gateway      = false
  single_nat_gateway    = false
  map_public_ip_on_launch = true

  public_subnet_tags = {
    # Usa a variável
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" 
    "kubernetes.io/role/elb"                      = "1"
  }
}

# Saídas internas do módulo (o `eks.tf` vai usá-las)
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}