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
  description = "Database droplet size slug"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "db_name" {
  type    = string
  default = "freelight"
}

variable "engine_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "node_count" {
  description = "Number of nodes. 1 = single, 2 = primary + standby, 3 = primary + 2 standby"
  type        = number
  default     = 1
}

# --- Managed PostgreSQL ---

resource "digitalocean_database_cluster" "postgres" {
  name                 = "${var.name_prefix}-db"
  engine               = "pg"
  version              = var.engine_version
  size                 = var.size
  region               = var.region
  node_count           = var.node_count
  private_network_uuid = var.vpc_id
}

resource "digitalocean_database_db" "main" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.db_name
}

# Restrict access to the VPC (trusted sources only)
resource "digitalocean_database_firewall" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "tag"
    value = "${var.name_prefix}-worker"
  }
}

# --- Outputs ---

output "host" {
  value = digitalocean_database_cluster.postgres.host
}

output "private_host" {
  value = digitalocean_database_cluster.postgres.private_host
}

output "port" {
  value = digitalocean_database_cluster.postgres.port
}

output "database_name" {
  value = digitalocean_database_db.main.name
}

output "user" {
  value = digitalocean_database_cluster.postgres.user
}

output "password" {
  value     = digitalocean_database_cluster.postgres.password
  sensitive = true
}

output "uri" {
  value     = digitalocean_database_cluster.postgres.uri
  sensitive = true
}

output "private_uri" {
  value     = digitalocean_database_cluster.postgres.private_uri
  sensitive = true
}

output "cluster_urn" {
  value = digitalocean_database_cluster.postgres.urn
}
