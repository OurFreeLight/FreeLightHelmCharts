# tf/gcp/variables.tf

variable "k8s_version" {
  description = "The version of Kubernetes to use"
  type        = string
  default     = "1.27"
}

variable "gcp_credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
}

variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources into"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP region to deploy resources into"
  type        = string
  default     = "us-central1-b"
}

# VM specific variables
variable "gcp_vm_instance_type" {
  description = "The instance type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "gcp_vm_image" {
  description = "The OS image for the VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

