variable "environment" {
  description = "Environment name (staging, production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sfo3"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "freelight"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "IP range for the VPC (e.g., 10.10.0.0/16)"
  type        = string
  default     = "10.10.0.0/16"
}

# --- Kubernetes (DOKS) ---

variable "enable_kubernetes" {
  description = "Whether to create a DOKS cluster"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "DOKS Kubernetes version prefix (e.g., '1.31'). The latest patch version is auto-selected."
  type        = string
  default     = "1.31"
}

variable "node_size" {
  description = "Droplet size for worker nodes. Cheap: s-1vcpu-2gb (~$12/mo), Mid: s-2vcpu-4gb (~$24/mo), Prod: s-4vcpu-8gb (~$48/mo)"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes (fixed count, not autoscaled)"
  type        = number
  default     = 2
}

variable "enable_autoscale" {
  description = "Enable cluster autoscaling. When true, node_count is used as min_nodes."
  type        = bool
  default     = false
}

variable "autoscale_max_nodes" {
  description = "Maximum nodes when autoscaling is enabled"
  type        = number
  default     = 5
}

# --- DNS ---

variable "domain" {
  description = "Primary domain name"
  type        = string
}

variable "enable_dns" {
  description = "Whether to manage DNS in DigitalOcean (set false if DNS is managed elsewhere, e.g., Route53)"
  type        = bool
  default     = false
}

# --- Database (Managed PostgreSQL) ---

variable "enable_database" {
  description = "Whether to create a managed PostgreSQL database"
  type        = bool
  default     = false
}

variable "db_size" {
  description = "Database droplet size. Cheap: db-s-1vcpu-1gb (~$15/mo), Mid: db-s-1vcpu-2gb (~$30/mo), Prod: db-s-2vcpu-4gb (~$60/mo)"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "freelight"
}

variable "db_engine_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "db_node_count" {
  description = "Number of database nodes. 1 = single node (cheap), 2 = primary + standby (HA), 3 = primary + 2 read replicas"
  type        = number
  default     = 1
}

# --- Cache (Managed Redis) ---

variable "enable_cache" {
  description = "Whether to create a managed Redis cache"
  type        = bool
  default     = false
}

variable "cache_size" {
  description = "Cache droplet size. Cheap: db-s-1vcpu-1gb (~$15/mo), Mid: db-s-1vcpu-2gb (~$30/mo), Prod: db-s-2vcpu-4gb (~$60/mo)"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "cache_node_count" {
  description = "Number of cache nodes. 1 = single (cheap), 2 = primary + standby (HA)"
  type        = number
  default     = 1
}

variable "cache_eviction_policy" {
  description = "Redis eviction policy"
  type        = string
  default     = "allkeys_lru"
}

# --- Object Storage (Spaces) ---

variable "enable_spaces" {
  description = "Whether to create a Spaces bucket for file uploads"
  type        = bool
  default     = false
}

variable "enable_spaces_cdn" {
  description = "Enable CDN for the Spaces bucket"
  type        = bool
  default     = false
}

# --- DO Project ---

variable "enable_project" {
  description = "Whether to create a DigitalOcean Project to group resources"
  type        = bool
  default     = true
}
