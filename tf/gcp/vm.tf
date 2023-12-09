# tf/gcp/vm.tf

data "template_file" "startup_microk8s_script" {
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

resource "google_compute_instance" "default" {
  name         = "freelight-vm"
  machine_type = var.gcp_vm_instance_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.gcp_vm_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = data.template_file.startup_microk8s_script.rendered
  tags = ["freelight-microk8s-firewall", "http-server", "https-server"]
}
