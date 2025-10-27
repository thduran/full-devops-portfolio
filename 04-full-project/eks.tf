module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.6.1" # it's not allowed to use variable here

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Links to VPC (vpc.tf)
  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  endpoint_public_access  = true
  endpoint_private_access = true

  # node group
  eks_managed_node_groups = {
    micro = {
      # dynamic name
      name           = "${var.cluster_name}-micro-nodes"
      instance_types = var.node_group_instance_types
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size

      ami_type               = "AL2_x86_64"                        # 👈 garante compatibilidade com EKS 1.29
      vpc_security_group_ids = [module.eks.node_security_group_id] # 👈 comunicação correta com o cluster

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }
}