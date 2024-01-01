# tf/aws/variables.tf

variable "k8s_version" {
  description = "The version of Kubernetes to use"
  type        = string
  default     = "1.27"
}

variable "k8s_type" {
  description = "Type of kubernetes deployment type. Can be: microk8s,eks"
  type        = string
  default     = "microk8s"

  validation {
    condition     = contains(["microk8s","eks"], var.k8s_type)
    error_message = "Invalid kubernetes deployment type. Must be: microk8s,eks"
  }
}

variable "frontend_deployment_type" {
  description = "Type of frontend deployment. Can be: none,cloudfront"
  type        = string

  validation {
    condition     = contains(["none", "cloudfront"], var.frontend_deployment_type)
    error_message = "Invalid frontend deployment type. Must be: none,cloudfront"
  }
}

variable "backend_deployment_type" {
  description = "Type of backend deployment. Can be: none,vm,eks"
  type        = string

  validation {
    condition     = contains(["none", "vm", "eks"], var.backend_deployment_type)
    error_message = "Invalid backend deployment type. Must be: none,vm,eks"
  }
}

variable "root_domain" {
  description = "The root domain used."
  type        = string
}

variable "domain" {
  description = "The domain to use for static web hosting."
  type        = string
}

variable "api_static_ip_name" {
  description = "The name of the existing static IP address for the API"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-west-2"
}

variable "aws_vm_admin_instance_type" {
  description = "The instance type for the admin VM"
  type        = string
  default     = "t3.medium"
}

variable "aws_vm_instance_type" {
  description = "The instance type for the VM"
  type        = string
  default     = "t3.small"
}

variable "aws_storage_size" {
  description = "The storage size of the VM or each AWS node"
  type        = string
  default     = 20
}

variable "aws_key_pair_name" {
  description = "The name of the key pair to use"
  type        = string
}

variable "aws_eks_cluster_iam_role_arn" {
  description = "The ARN of the existing IAM role for the EKS cluster"
  type        = string
}

variable "aws_eks_node_group_iam_role_arn" {
  description = "The ARN of the existing IAM role for the EKS node group"
  type        = string
}

variable "delete_protection" {
  description = "Will enable delete protection on the environment being created."
  type        = bool
  default     = true
}