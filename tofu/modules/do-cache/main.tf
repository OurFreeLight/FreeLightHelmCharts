variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "size" {
  description = "Cache droplet size slug"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "node_count" {
  description = "Number of nodes. 1 = single, 2 = primary + standby"
  type        = number
  default     = 1
}

variable "eviction_policy" {
  description = "Redis eviction policy"
  type        = string
  default     = "allkeys_lru"
}

# --- Managed Redis ---

resource "digitalocean_database_cluster" "redis" {
  name                 = "${var.name_prefix}-cache"
  engine               = "redis"
  version              = "7"
  size                 = var.size
  region               = var.region
  node_count           = var.node_count
  private_network_uuid = var.vpc_id
  eviction_policy      = var.eviction_policy
}

# Restrict access to the VPC (trusted sources only)
resource "digitalocean_database_firewall" "redis" {
  cluster_id = digitalocean_database_cluster.redis.id

  rule {
    type  = "tag"
    value = "${var.name_prefix}-worker"
  }
}

# --- Outputs ---

output "host" {
  value = digitalocean_database_cluster.redis.host
}

output "private_host" {
  value = digitalocean_database_cluster.redis.private_host
}

output "port" {
  value = digitalocean_database_cluster.redis.port
}

output "password" {
  value     = digitalocean_database_cluster.redis.password
  sensitive = true
}

output "uri" {
  value     = digitalocean_database_cluster.redis.uri
  sensitive = true
}

output "private_uri" {
  value     = digitalocean_database_cluster.redis.private_uri
  sensitive = true
}

output "cluster_urn" {
  value = digitalocean_database_cluster.redis.urn
}
