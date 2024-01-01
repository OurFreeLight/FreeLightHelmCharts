# tf/aws/main.tf

terraform {
  required_version = ">= 1.2.0"
  backend "local" {
    path = "./dist/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS Provider specific to us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
