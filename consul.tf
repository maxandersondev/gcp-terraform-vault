// testing instance groups
resource "google_compute_region_autoscaler" "consul" {
  name   = "hashi-consul-region-autoscaler"
  //region = "us-central1"
  target = google_compute_region_instance_group_manager.consul.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "consul" {
  name           = "hashi-consul-instance-template"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["consul-member"]

  metadata_startup_script = data.template_file.default.rendered

  disk {
    source_image = data.google_compute_image.centos_8.self_link
  }

  network_interface {
    network = "default" //google_compute_network.managment.self_link
  }

  network_interface {
    subnetwork    = google_compute_subnetwork.management-sub.self_link
    access_config = {}
  }

  network_interface {
    subnetwork = google_compute_subnetwork.trust-sub.self_link
  }

  metadata = {
    name = "consul-server"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "consul" {
  name = "hashi-consul-target-pool"
}

resource "google_compute_region_instance_group_manager" "consul" {
  name   = "hashi-consul-region-igm"
  region = var.gcp_region

  version {
    instance_template  = google_compute_instance_template.consul.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.consul.id]
  base_instance_name = "hashi-consul"
  wait_for_instances = true
}

output "target_pools_members" {
  value = google_compute_target_pool.consul.instances
}

output "startup_script_rendered" {
  value = data.template_file.default.rendered
}

data "template_file" "default" {
  template = file("${path.module}/scripts/consul-config.tpl")
  vars = {
    consul_download_url = "releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip"
  }
}

data "google_compute_image" "debian_9" {
  family  = "debian-9"
  project = "debian-cloud"
}

data "google_compute_image" "centos_8" {
  family  = "centos-8"
  project = "centos-cloud"
}