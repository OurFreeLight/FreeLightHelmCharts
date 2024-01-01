resource "google_storage_bucket" "static_site_bucket" {
  name               = var.domain
  location           = var.gcp_bucket_location
  force_destroy      = !var.delete_protection
  count              = var.frontend_deployment_type == "gcs" ? 1 : 0

  website {
    main_page_suffix = "latest/"
    not_found_page   = "latest/index.html"  # Redirect 404s to index.html
  }
}

data "google_compute_global_address" "frontend_static_ip" {
  name = var.frontend_static_ip_name
  count = var.frontend_static_ip_name != "" ? 1 : 0
}

resource "google_storage_bucket_iam_binding" "bucket_object_reader" {
  bucket = google_storage_bucket.static_site_bucket[0].name
  role   = "roles/storage.objectViewer"
  count  = var.frontend_deployment_type == "gcs" ? 1 : 0

  members = [
    "allUsers",
  ]
}

resource "google_compute_backend_bucket" "static_site_backend" {
  name        = "freelight-frontend-backend-haha"
  count       = var.frontend_deployment_type == "gcs" ? 1 : 0

  bucket_name = google_storage_bucket.static_site_bucket[0].name
  enable_cdn  = true
}

resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  name    = "freelight-managed-cert"
  count   = var.frontend_deployment_type == "gcs" ? 1 : 0

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "freelight-https-lb-proxy"
  count            = var.frontend_deployment_type == "gcs" ? 1 : 0

  url_map          = google_compute_url_map.url_map[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_certificate[0].id]
}

resource "google_compute_url_map" "url_map" {
  name            = "freelight-web-url-map"
  count           = var.frontend_deployment_type == "gcs" ? 1 : 0

  default_service = google_compute_backend_bucket.static_site_backend[0].id
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name       = "freelight-https-content-rule"
  count      = var.frontend_deployment_type == "gcs" ? 1 : 0

  target     = google_compute_target_https_proxy.https_proxy[0].id
  port_range = "443"

  ip_address = data.google_compute_global_address.frontend_static_ip[0].address
}
