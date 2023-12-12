# tf/gcp/variables.tf

variable "k8s_version" {
  description = "The version of Kubernetes to use"
  type        = string
  default     = "1.27"
}

variable "deployment_type" {
  description = "Type of deployment. Can be: vm,gke"
  type        = string

  validation {
    condition     = contains(["vm", "gke"], var.deployment_type)
    error_message = "Invalid deployment type. Must be: vm,gke"
  }
}

variable "static_ip_name" {
  description = "The name of the existing GCP static IP address"
  type        = string
  default     = ""
}

variable "k8s_type" {
  description = "Type of kubernetes deployment type. Can be: microk8s,gke"
  type        = string
  default     = "microk8s"

  validation {
    condition     = contains(["microk8s","gke"], var.k8s_type)
    error_message = "Invalid kubernetes deployment type. Must be: microk8s,gke"
  }
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
variable "gcp_vm_admin_instance_type" {
  description = "The instance type for the admin VM"
  type        = string
  default     = "e2-standard-4"
}

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

variable "gcp_network_tier" {
  description = "The network tier for the VM"
  type        = string
  default     = "STANDARD"
}

variable "gcp_gke_channel" {
  description = "The release channel to use for GKE. Can be: RAPID,REGULAR,STABLE"
  type        = string
  default     = "STABLE"
}

variable "gcp_storage_size" {
  description = "The storage size of the VM or each GKE node"
  type        = string
  default     = 20
}

variable "delete_protection" {
  description = "Will enable delete protection on the environment being created."
  type        = bool
  default     = true
}

