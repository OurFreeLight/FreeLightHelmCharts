variable "domain" {
  description = "Primary domain name"
  type        = string
}

variable "zone_id" {
  description = "Existing Route53 hosted zone ID. If empty, a new zone is created."
  type        = string
  default     = ""
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type    = string
    records = optional(list(string))
    ttl     = optional(number, 300)
    alias   = optional(object({
      name    = string
      zone_id = string
    }))
  }))
  default = {}
}

# Use existing zone or create new one
resource "aws_route53_zone" "main" {
  count = var.zone_id == "" ? 1 : 0
  name  = var.domain
}

locals {
  zone_id = var.zone_id != "" ? var.zone_id : aws_route53_zone.main[0].zone_id
}

# Create DNS records
resource "aws_route53_record" "records" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.key
  type    = each.value.type

  # Standard record
  records = each.value.alias == null ? each.value.records : null
  ttl     = each.value.alias == null ? each.value.ttl : null

  # Alias record
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = false
    }
  }
}

# --- Outputs ---

output "zone_id" {
  value = local.zone_id
}

output "nameservers" {
  value = var.zone_id == "" ? aws_route53_zone.main[0].name_servers : []
}
