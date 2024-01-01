# AWS Installation
This directory contains the Terraform scripts to install the AWS infrastructure for the project.

## Prerequisites
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [Terraform](https://www.terraform.io/downloads.html)

## Getting Started
Create a user with the DevOps Policy. The DevOps policy should include:
    * Certificate Manager: Full Access
    * CloudFront: Full Access
    * EC2: Full Access
    * EKS: Full Access
    * Elastic Container Registry: Full Access
    * IAM: Full Access
    * S3: Full Access
    * Route 53: Full Access
NOTE: This will have to be corrected in the future as it's not ideal to give the DevOps policy this much access. Especially to the IAM permissions.

Now, setup the AWS CLI with the user credentials, then create a `custom.tfvars` file in this directory with the following variables set:
```terraform
domain                          = "staging.freelight.org"
k8s_version                     = "1.26"
frontend_deployment_type        = "cloudfront"
backend_deployment_type         = "eks"
aws_eks_cluster_iam_role_arn    = "<EKS_CLUSTER_ARN>"
aws_eks_node_group_iam_role_arn = "<EKS_NODE_GROUP_ARN>"
```