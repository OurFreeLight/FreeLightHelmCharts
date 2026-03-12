provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}

# Required for ACM certificates used by CloudFront (must be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Default to first 2 AZs in the region if not specified
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    data.aws_availability_zones.available.names, 0, 2
  )

  # When NAT is disabled, use public subnets for everything (EKS, DB, cache)
  # When NAT is enabled, use private subnets for workloads
  workload_subnet_ids = var.enable_nat_gateway ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
}

data "aws_availability_zones" "available" {
  state = "available"
}

# --- Networking ---

module "networking" {
  source = "../modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  enable_nat_gateway = var.enable_nat_gateway
}

# --- Kubernetes (EKS) ---

module "kubernetes" {
  source = "../modules/kubernetes"
  count  = var.enable_eks ? 1 : 0

  name_prefix        = local.name_prefix
  kubernetes_version = var.kubernetes_version
  subnet_ids          = local.workload_subnet_ids
  node_instance_types = var.node_instance_types
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_desired_size  = var.node_desired_size
  use_spot_instances = var.use_spot_instances
}

# --- Static Sites (S3 + CloudFront) ---

module "static_site" {
  source   = "../modules/static-site"
  for_each = var.static_sites

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix = local.name_prefix
  site_name   = each.key
  domain_name = each.value.domain_name
  zone_id     = each.value.zone_id
}

# --- DNS ---

module "dns" {
  source = "../modules/dns"

  domain  = var.domain
  zone_id = var.route53_zone_id
}

# --- Database (RDS PostgreSQL) ---

module "database" {
  source = "../modules/database"
  count  = var.enable_rds ? 1 : 0

  name_prefix       = local.name_prefix
  engine_type       = var.rds_engine_type
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  db_name           = var.rds_db_name
  read_replicas     = var.rds_read_replicas
  subnet_ids        = local.workload_subnet_ids
  vpc_id            = module.networking.vpc_id
  allowed_security_group_ids = var.enable_eks ? [module.kubernetes[0].node_security_group_id] : []
}

# --- Cache (ElastiCache) ---

module "cache" {
  source = "../modules/cache"
  count  = var.enable_cache ? 1 : 0

  name_prefix        = local.name_prefix
  engine_type        = var.cache_engine_type
  node_type          = var.cache_node_type
  num_shards         = var.cache_num_shards
  replicas_per_shard = var.cache_replicas_per_shard
  subnet_ids         = local.workload_subnet_ids
  vpc_id             = module.networking.vpc_id
  allowed_security_group_ids = var.enable_eks ? [module.kubernetes[0].node_security_group_id] : []
}

# --- S3 Storage (uploads + backups) ---
# Always created — S3 is used from any cloud provider's K8s cluster.

module "storage" {
  source = "../modules/storage"

  name_prefix           = local.name_prefix
  enable_backups_bucket = var.enable_backups_bucket
}
