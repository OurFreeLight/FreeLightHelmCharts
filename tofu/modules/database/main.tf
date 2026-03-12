variable "name_prefix" {
  type = string
}

variable "engine_type" {
  description = "Database engine: 'postgres' for standard RDS PostgreSQL (cheaper), 'aurora' for Aurora Serverless v2 (auto-scaling)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "aurora"], var.engine_type)
    error_message = "engine_type must be 'postgres' or 'aurora'."
  }
}

variable "instance_class" {
  description = "RDS instance class (only used when engine_type = 'postgres')"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage in GB (only used when engine_type = 'postgres')"
  type        = number
  default     = 20
}

variable "db_name" {
  type    = string
  default = "freelight"
}

variable "engine_version" {
  description = "PostgreSQL version. Use major version like '16' for both engine types."
  type        = string
  default     = "16"
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Multi-AZ deployment (only used when engine_type = 'postgres')"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "read_replicas" {
  description = "Number of read replicas (only used when engine_type = 'postgres'). Scale reads by adding replicas — each gets its own endpoint."
  type        = number
  default     = 0
}

variable "aurora_min_capacity" {
  description = "Minimum ACU for Aurora Serverless v2 (0.5 = ~$43/mo floor)"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Maximum ACU for Aurora Serverless v2"
  type        = number
  default     = 2.0
}

# --- Shared Resources ---

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name_prefix}-db-subnet-group" }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name_prefix}-db-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "db_ingress" {
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.db.id
}

resource "random_password" "db" {
  length  = 32
  special = false
}

# =============================================================================
# Option A: Standard RDS PostgreSQL (cheaper — db.t4g.micro ~$12/mo)
# =============================================================================

resource "aws_db_instance" "postgres" {
  count = var.engine_type == "postgres" ? 1 : 0

  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = "freelight"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true

  tags = { Name = "${var.name_prefix}-db" }
}

# --- Read Replicas (standard RDS only) ---
#
# Scale reads by adding replicas. Each replica gets its own endpoint.
# Replicas also serve as failover targets if the primary goes down.
#
# Scaling path:
#   0 replicas → single instance, all reads/writes on primary
#   1 replica  → offload reads, automatic failover target
#   2 replicas → 3x read throughput, higher availability

resource "aws_db_instance" "read_replica" {
  count = var.engine_type == "postgres" ? var.read_replicas : 0

  identifier          = "${var.name_prefix}-db-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.postgres[0].identifier
  instance_class      = var.instance_class
  storage_encrypted   = true

  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az            = false
  skip_final_snapshot = true

  tags = { Name = "${var.name_prefix}-db-replica-${count.index + 1}" }
}

# =============================================================================
# Option B: Aurora Serverless v2 (auto-scaling, higher minimum cost)
# =============================================================================

resource "aws_rds_cluster" "aurora" {
  count = var.engine_type == "aurora" ? 1 : 0

  cluster_identifier      = "${var.name_prefix}-db"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = var.engine_version
  database_name           = var.db_name
  master_username         = "freelight"
  master_password         = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  backup_retention_period = var.backup_retention_period

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count = var.engine_type == "aurora" ? 1 : 0

  identifier         = "${var.name_prefix}-db-1"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
}

# --- Outputs ---

output "endpoint" {
  value = var.engine_type == "postgres" ? aws_db_instance.postgres[0].address : aws_rds_cluster.aurora[0].endpoint
}

output "reader_endpoints" {
  description = "Read replica endpoints (standard RDS) or Aurora reader endpoint"
  value = (
    var.engine_type == "postgres"
    ? [for r in aws_db_instance.read_replica : r.address]
    : var.engine_type == "aurora" ? [aws_rds_cluster.aurora[0].reader_endpoint] : []
  )
}

output "port" {
  value = 5432
}

output "db_name" {
  value = var.db_name
}

output "master_username" {
  value = "freelight"
}

output "master_password" {
  value     = random_password.db.result
  sensitive = true
}
