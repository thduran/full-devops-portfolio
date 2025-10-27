module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0" # it's not allowed to use variable here

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_subnets_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets # 👈 ESSENCIAL para NAT Gateway funcionar

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

}
