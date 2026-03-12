variable "name_prefix" {
  type = string
}

variable "region" {
  description = "Spaces region (not all DO regions support Spaces: nyc3, sfo3, ams3, sgp1, fra1, syd1)"
  type        = string
}

variable "enable_cdn" {
  description = "Enable CDN for the Spaces bucket"
  type        = bool
  default     = false
}

# --- Spaces Bucket ---

resource "digitalocean_spaces_bucket" "uploads" {
  name   = "${var.name_prefix}-uploads"
  region = var.region
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

# --- CDN (optional) ---

resource "digitalocean_cdn" "uploads" {
  count  = var.enable_cdn ? 1 : 0
  origin = digitalocean_spaces_bucket.uploads.bucket_domain_name
}

# --- Outputs ---

output "endpoint" {
  value = digitalocean_spaces_bucket.uploads.endpoint
}

output "bucket_name" {
  value = digitalocean_spaces_bucket.uploads.name
}

output "bucket_domain_name" {
  value = digitalocean_spaces_bucket.uploads.bucket_domain_name
}

output "bucket_urn" {
  value = digitalocean_spaces_bucket.uploads.urn
}

output "cdn_domain" {
  value = var.enable_cdn ? digitalocean_cdn.uploads[0].endpoint : null
}
