variable "environment" {
  description = "Environment name (staging, production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "freelight"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway. When false, EKS nodes use public subnets (saves ~$32/mo). Enable for production if you need private-only nodes."
  type        = bool
  default     = false
}

# --- Kubernetes (EKS) ---

variable "enable_eks" {
  description = "Whether to create an EKS cluster"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "use_spot_instances" {
  description = "Use spot instances for EKS node group (saves ~60-70% but instances can be reclaimed)"
  type        = bool
  default     = false
}

# --- Static Sites ---

variable "static_sites" {
  description = "Map of static sites to deploy via S3 + CloudFront"
  type = map(object({
    domain_name = string
    zone_id     = string
  }))
  default = {}
}

# --- DNS ---

variable "domain" {
  description = "Primary domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Existing Route53 hosted zone ID for the primary domain"
  type        = string
  default     = ""
}

# --- Database (RDS) ---

variable "enable_rds" {
  description = "Whether to create an RDS PostgreSQL instance"
  type        = bool
  default     = false
}

variable "rds_engine_type" {
  description = "'postgres' for standard RDS (~$12/mo with t4g.micro), 'aurora' for Aurora Serverless v2 (~$43/mo min, auto-scaling)"
  type        = string
  default     = "postgres"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_db_name" {
  description = "Database name"
  type        = string
  default     = "freelight"
}

variable "rds_read_replicas" {
  description = "Number of read replicas (standard RDS only). 0 = no replicas."
  type        = number
  default     = 0
}

# --- Cache (ElastiCache) ---

variable "enable_cache" {
  description = "Whether to create an ElastiCache cluster"
  type        = bool
  default     = false
}

variable "cache_engine_type" {
  description = "'cluster' for Cluster Mode (~$12/mo start, scale via shards+replicas), 'serverless' for auto-scaling (~$90/mo min)"
  type        = string
  default     = "cluster"
}

variable "cache_node_type" {
  description = "ElastiCache node type (cluster mode only)"
  type        = string
  default     = "cache.t4g.micro"
}

variable "cache_num_shards" {
  description = "Number of shards. More shards = more write throughput + memory capacity."
  type        = number
  default     = 1
}

variable "cache_replicas_per_shard" {
  description = "Read replicas per shard. More replicas = more read throughput + automatic failover."
  type        = number
  default     = 0
}

# --- S3 Storage ---

variable "enable_backups_bucket" {
  description = "Create a separate S3 bucket for database backups with lifecycle rules (auto-transition to cheaper storage)"
  type        = bool
  default     = false
}
