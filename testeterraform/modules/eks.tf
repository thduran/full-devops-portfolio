resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name # Usa a variável
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids             = module.vpc.public_subnets # Referência local
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-workers" # Usa a variável
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.public_subnets # Referência local

  instance_types = [var.instance_type] # Usa a variável

  scaling_config {
    desired_size = var.node_desired_size # Usa a variável
    max_size     = var.node_max_size     # Usa a variável
    min_size     = var.node_min_size     # Usa a variável
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly,
  ]
}