variable "name_prefix" {
  type = string
}

variable "engine_type" {
  description = "'cluster' for ElastiCache Cluster Mode (~$12/mo start, manually scalable), 'serverless' for ElastiCache Serverless (~$90/mo min, auto-scaling)"
  type        = string
  default     = "cluster"

  validation {
    condition     = contains(["cluster", "serverless"], var.engine_type)
    error_message = "engine_type must be 'cluster' or 'serverless'."
  }
}

variable "node_type" {
  description = "Node type for cluster mode"
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "7.2"
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the cache"
  type        = list(string)
  default     = []
}

# --- Cluster Mode scaling knobs ---

variable "num_shards" {
  description = "Number of shards (node groups) in cluster mode. More shards = more write throughput and memory. Each shard holds a portion of the keyspace."
  type        = number
  default     = 1
}

variable "replicas_per_shard" {
  description = "Number of read replicas per shard. More replicas = more read throughput and failover capacity."
  type        = number
  default     = 0
}

# --- Serverless scaling knobs ---

variable "serverless_max_storage_gb" {
  description = "Maximum data storage in GB for serverless"
  type        = number
  default     = 1
}

variable "serverless_max_ecpu" {
  description = "Maximum ECPUs per second for serverless"
  type        = number
  default     = 1000
}

# --- Shared Resources ---

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-cache"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "cache" {
  name_prefix = "${var.name_prefix}-cache-"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name_prefix}-cache-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cache_ingress" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.cache.id
}

# =============================================================================
# Option A: ElastiCache Cluster Mode (~$12/mo start, horizontally scalable)
#
# Scale by adjusting:
#   num_shards         - add shards for more write throughput + memory
#   replicas_per_shard - add replicas for more read throughput + HA
#   node_type          - upgrade for more memory/CPU per node
#
# Example scaling path:
#   Start:  1 shard, 0 replicas, t4g.micro  (~$12/mo,  0.5GB)
#   Step 1: 1 shard, 1 replica,  t4g.micro  (~$24/mo,  0.5GB + read HA)
#   Step 2: 2 shards, 1 replica, t4g.small  (~$96/mo,  2.8GB, 2x write)
#   Step 3: 4 shards, 2 replicas, t4g.medium (~$576/mo, 12GB, 4x write)
# =============================================================================

resource "aws_elasticache_replication_group" "cluster" {
  count = var.engine_type == "cluster" ? 1 : 0

  replication_group_id = "${var.name_prefix}-cache"
  description          = "${var.name_prefix} Valkey cluster"
  engine               = "valkey"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379

  # Cluster mode settings
  num_node_groups         = var.num_shards
  replicas_per_node_group = var.replicas_per_shard

  # Networking
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.cache.id]

  # Enable in-transit encryption (compatible with Garnet/Valkey clients)
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true

  # Allow scaling without downtime
  automatic_failover_enabled = var.replicas_per_shard > 0

  tags = { Name = "${var.name_prefix}-cache" }
}

# =============================================================================
# Option B: ElastiCache Serverless (auto-scaling, ~$90/mo minimum)
# =============================================================================

resource "aws_elasticache_serverless_cache" "serverless" {
  count  = var.engine_type == "serverless" ? 1 : 0
  engine = "valkey"
  name   = "${var.name_prefix}-cache"

  cache_usage_limits {
    data_storage {
      maximum = var.serverless_max_storage_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.serverless_max_ecpu
    }
  }

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.cache.id]
}

# --- Outputs ---

output "endpoint" {
  description = "Cache endpoint. For cluster mode this is the configuration endpoint (supports automatic discovery of shards)."
  value = (
    var.engine_type == "cluster"
    ? aws_elasticache_replication_group.cluster[0].configuration_endpoint_address
    : aws_elasticache_serverless_cache.serverless[0].endpoint[0].address
  )
}

output "port" {
  value = (
    var.engine_type == "cluster"
    ? 6379
    : aws_elasticache_serverless_cache.serverless[0].endpoint[0].port
  )
}

output "engine_type" {
  value = var.engine_type
}
