# tf/gcp/main.tf

terraform {
  required_version = ">= 1.2.0"
  backend "local" {
    path = "./dist/terraform.tfstate"
  }
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

provider "google-beta" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}
