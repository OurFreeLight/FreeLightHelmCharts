provider "digitalocean" {
  # Token is read from DIGITALOCEAN_TOKEN environment variable
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# --- Networking (VPC) ---

module "networking" {
  source = "../modules/do-networking"

  name_prefix = local.name_prefix
  region      = var.region
  vpc_cidr    = var.vpc_cidr
}

# --- Kubernetes (DOKS) ---

module "kubernetes" {
  source = "../modules/do-kubernetes"
  count  = var.enable_kubernetes ? 1 : 0

  name_prefix         = local.name_prefix
  region              = var.region
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.networking.vpc_id
  node_size           = var.node_size
  node_count          = var.node_count
  enable_autoscale    = var.enable_autoscale
  autoscale_max_nodes = var.autoscale_max_nodes
}

# --- DNS ---

module "dns" {
  source = "../modules/do-dns"
  count  = var.enable_dns ? 1 : 0

  domain = var.domain
}

# --- Database (Managed PostgreSQL) ---

module "database" {
  source = "../modules/do-database"
  count  = var.enable_database ? 1 : 0

  name_prefix    = local.name_prefix
  region         = var.region
  vpc_id         = module.networking.vpc_id
  size           = var.db_size
  db_name        = var.db_name
  engine_version = var.db_engine_version
  node_count     = var.db_node_count
}

# --- Cache (Managed Redis) ---

module "cache" {
  source = "../modules/do-cache"
  count  = var.enable_cache ? 1 : 0

  name_prefix     = local.name_prefix
  region          = var.region
  vpc_id          = module.networking.vpc_id
  size            = var.cache_size
  node_count      = var.cache_node_count
  eviction_policy = var.cache_eviction_policy
}

# --- Object Storage (Spaces) ---

module "spaces" {
  source = "../modules/do-spaces"
  count  = var.enable_spaces ? 1 : 0

  name_prefix = local.name_prefix
  region      = var.region
  enable_cdn  = var.enable_spaces_cdn
}

# --- DO Project (groups all resources in the DO dashboard) ---

resource "digitalocean_project" "main" {
  count = var.enable_project ? 1 : 0

  name        = local.name_prefix
  description = "FreeLight ${var.environment} environment"
  purpose     = "Web Application"
  environment = var.environment == "production" ? "Production" : "Staging"
}
