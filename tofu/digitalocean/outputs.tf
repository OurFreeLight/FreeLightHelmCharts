output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "kubernetes_cluster_id" {
  description = "DOKS cluster ID"
  value       = var.enable_kubernetes ? module.kubernetes[0].cluster_id : null
}

output "kubernetes_cluster_name" {
  description = "DOKS cluster name"
  value       = var.enable_kubernetes ? module.kubernetes[0].cluster_name : null
}

output "kubernetes_endpoint" {
  description = "DOKS cluster API endpoint"
  value       = var.enable_kubernetes ? module.kubernetes[0].endpoint : null
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = var.enable_kubernetes ? "doctl kubernetes cluster kubeconfig save ${module.kubernetes[0].cluster_id}" : null
}

output "database_host" {
  description = "Managed PostgreSQL host"
  value       = var.enable_database ? module.database[0].host : null
}

output "database_port" {
  description = "Managed PostgreSQL port"
  value       = var.enable_database ? module.database[0].port : null
}

output "database_name" {
  description = "Managed PostgreSQL database name"
  value       = var.enable_database ? module.database[0].database_name : null
}

output "database_user" {
  description = "Managed PostgreSQL user"
  value       = var.enable_database ? module.database[0].user : null
}

output "database_password" {
  description = "Managed PostgreSQL password"
  value       = var.enable_database ? module.database[0].password : null
  sensitive   = true
}

output "database_uri" {
  description = "Managed PostgreSQL connection URI"
  value       = var.enable_database ? module.database[0].uri : null
  sensitive   = true
}

output "database_private_host" {
  description = "Managed PostgreSQL private host (VPC-only access)"
  value       = var.enable_database ? module.database[0].private_host : null
}

output "cache_host" {
  description = "Managed Redis host"
  value       = var.enable_cache ? module.cache[0].host : null
}

output "cache_port" {
  description = "Managed Redis port"
  value       = var.enable_cache ? module.cache[0].port : null
}

output "cache_password" {
  description = "Managed Redis password"
  value       = var.enable_cache ? module.cache[0].password : null
  sensitive   = true
}

output "cache_private_host" {
  description = "Managed Redis private host (VPC-only access)"
  value       = var.enable_cache ? module.cache[0].private_host : null
}

output "cache_uri" {
  description = "Managed Redis connection URI"
  value       = var.enable_cache ? module.cache[0].uri : null
  sensitive   = true
}

output "spaces_endpoint" {
  description = "Spaces endpoint URL"
  value       = var.enable_spaces ? module.spaces[0].endpoint : null
}

output "spaces_bucket_name" {
  description = "Spaces bucket name"
  value       = var.enable_spaces ? module.spaces[0].bucket_name : null
}

output "spaces_cdn_domain" {
  description = "Spaces CDN domain (if enabled)"
  value       = var.enable_spaces ? module.spaces[0].cdn_domain : null
}
