# tf/aws/eks.tf

resource "aws_eks_cluster" "freelight_cluster" {
  name     = "freelight-cluster"
  version  = var.k8s_version
  count    = var.backend_deployment_type == "eks" ? 1 : 0

  role_arn = var.aws_eks_cluster_iam_role_arn

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "10.100.0.0/16"
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    subnet_ids = data.aws_subnets.eks_subnets.ids
  }
}

data "aws_subnets" "eks_subnets" {}

resource "aws_eks_node_group" "freelight_node_group" {
  cluster_name    = aws_eks_cluster.freelight_cluster[0].name
  count           = var.backend_deployment_type == "eks" ? 1 : 0

  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  disk_size      = var.aws_storage_size
  instance_types = [var.aws_vm_instance_type]
  node_group_name = "freelight-node-group-1"
  node_role_arn   = var.aws_eks_node_group_iam_role_arn
  release_version = "1.26.10-20231201"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  subnet_ids      = data.aws_subnets.eks_subnets.ids

  update_config {
    max_unavailable = 1
  }

  version = var.k8s_version
}
