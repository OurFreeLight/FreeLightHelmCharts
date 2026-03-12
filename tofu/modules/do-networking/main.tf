variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC (e.g., 10.10.0.0/16)"
  type        = string
  default     = "10.10.0.0/16"
}

# --- VPC ---

resource "digitalocean_vpc" "main" {
  name     = "${var.name_prefix}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# --- Outputs ---

output "vpc_id" {
  value = digitalocean_vpc.main.id
}

output "vpc_urn" {
  value = digitalocean_vpc.main.urn
}
