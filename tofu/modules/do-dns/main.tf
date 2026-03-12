variable "domain" {
  description = "Primary domain name"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type     = string
    value    = string
    ttl      = optional(number, 300)
    priority = optional(number)
  }))
  default = {}
}

# --- Domain ---

resource "digitalocean_domain" "main" {
  name = var.domain
}

# --- DNS Records ---

resource "digitalocean_record" "records" {
  for_each = var.records

  domain   = digitalocean_domain.main.id
  name     = each.key
  type     = each.value.type
  value    = each.value.value
  ttl      = each.value.ttl
  priority = each.value.priority
}

# --- Outputs ---

output "domain_urn" {
  value = digitalocean_domain.main.urn
}

output "nameservers" {
  description = "DigitalOcean nameservers to point your registrar at"
  value       = ["ns1.digitalocean.com", "ns2.digitalocean.com", "ns3.digitalocean.com"]
}
