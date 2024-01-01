# tf/gcp/microk8s_vm.tf

data "template_file" "microk8s_startup_script" {
  count    = var.backend_deployment_type == "vm" ? (var.k8s_type == "microk8s" ? 1 : 0) : 0

  template = join ("\n", [
      file("../scripts/ubuntu-22.04/setup-vm.sh"),
      file("../scripts/ubuntu-22.04/install-microk8s.tpl"),
      file("../scripts/ubuntu-22.04/install-helm.sh"),
      file("../scripts/ubuntu-22.04/install-kubectl.sh"),
      file("../scripts/ubuntu-22.04/finish-vm.sh")
    ])

  vars = {
    k8s_version = var.k8s_version
  }
}

resource "google_compute_firewall" "microk8s_firewall" {
  name    = "microk8s-firewall"
  network = "default"
  count   = var.k8s_type == "microk8s" ? 1 : 0

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "16443"]
  }

  # The following argument is optional and can be adjusted as needed.
  # It restricts the source IPs allowed to access the VM.
  # If omitted, it allows access from any IP.
  source_ranges = ["0.0.0.0/0"]

  target_tags = ["freelight-microk8s-firewall"]
}

data "google_compute_address" "static_ip" {
  count = var.api_static_ip_name != "" ? 1 : 0
  name = var.api_static_ip_name
}

resource "google_compute_instance" "microk8s_vm" {
  name                = "freelight-vm"
  count               = var.backend_deployment_type == "vm" ? (var.k8s_type == "microk8s" ? 1 : 0) : 0
  machine_type        = var.gcp_vm_instance_type
  zone                = var.gcp_zone
  deletion_protection = var.delete_protection

  boot_disk {
    initialize_params {
      image = var.gcp_vm_image
      size = var.gcp_storage_size
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.api_static_ip_name != "" ? data.google_compute_address.static_ip[0].address : null
      network_tier = var.gcp_network_tier
    }
  }

  metadata_startup_script = data.template_file.microk8s_startup_script[0].rendered
  tags = ["freelight-microk8s-firewall", "http-server", "https-server"]
}
