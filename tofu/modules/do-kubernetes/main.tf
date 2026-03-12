variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "node_size" {
  description = "Droplet size slug for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes (used as min_nodes when autoscaling)"
  type        = number
  default     = 2
}

variable "enable_autoscale" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "autoscale_max_nodes" {
  description = "Maximum nodes when autoscaling is enabled"
  type        = number
  default     = 5
}

# Look up the latest patch version matching the requested prefix
data "digitalocean_kubernetes_versions" "main" {
  version_prefix = "${var.kubernetes_version}."
}

# --- DOKS Cluster ---

resource "digitalocean_kubernetes_cluster" "main" {
  name     = "${var.name_prefix}-k8s"
  region   = var.region
  version  = data.digitalocean_kubernetes_versions.main.latest_version
  vpc_uuid = var.vpc_id

  # Destroy associated LBs and volumes on cluster destroy
  destroy_all_associated_resources = true

  node_pool {
    name       = "${var.name_prefix}-workers"
    size       = var.node_size
    node_count = var.enable_autoscale ? null : var.node_count
    auto_scale = var.enable_autoscale
    min_nodes  = var.enable_autoscale ? var.node_count : null
    max_nodes  = var.enable_autoscale ? var.autoscale_max_nodes : null

    tags = ["${var.name_prefix}-worker"]
  }

  tags = [var.name_prefix]
}

# --- Outputs ---

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = digitalocean_kubernetes_cluster.main.name
}

output "endpoint" {
  value = digitalocean_kubernetes_cluster.main.endpoint
}

output "cluster_urn" {
  value = digitalocean_kubernetes_cluster.main.urn
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive = true
}
