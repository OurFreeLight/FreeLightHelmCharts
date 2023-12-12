# tf/gcp/gke.tf

resource "google_container_cluster" "freelight_cluster" {
  provider           = google-beta
  name               = "freelight-cluster"
  location           = var.gcp_zone
  count              = var.k8s_type == "gke" ? 1 : 0
  initial_node_count = 1

  deletion_protection = var.delete_protection

  min_master_version = var.k8s_version

  default_max_pods_per_node = 110

  release_channel {
    channel = var.gcp_gke_channel
  }

  node_config {
    machine_type = var.gcp_vm_admin_instance_type
    disk_size_gb = var.gcp_storage_size
    disk_type    = "pd-balanced"
    image_type   = "COS_CONTAINERD"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_container_node_pool" "freelight_pool_1" {
  provider   = google-beta
  name       = "freelight-pool-1"
  count      = var.k8s_type == "gke" ? 1 : 0
  location   = var.gcp_zone
  cluster    = google_container_cluster.freelight_cluster[0].name
  node_count = 1

  node_config {
    machine_type = var.gcp_vm_instance_type
    disk_size_gb = var.gcp_storage_size
    disk_type    = "pd-balanced"
    image_type   = "COS_CONTAINERD"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

