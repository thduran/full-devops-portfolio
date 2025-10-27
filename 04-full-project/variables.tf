variable "aws_region" {
  description = "AWS region where the resources will be created."
  type        = string
}

variable "vpc_name" {
  description = "VPC name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "vpc_subnets_azs" {
  description = "Availability zones the VPC must create the subnets"
  type        = list(string)
}


variable "vpc_private_subnets" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster."
  type        = string
}

variable "node_group_instance_types" {
  description = "Instance types for the EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 2
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}