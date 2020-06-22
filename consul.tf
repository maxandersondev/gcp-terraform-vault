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
  description    = "This template will be used to set up consul nodes"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["consul-member", "consul-cluster-node"]

  metadata_startup_script = data.template_file.default.rendered
  //metadata_startup_script = google_storage_bucket_object.consul-startup.self_link
  disk {
    source_image = data.google_compute_image.centos_8.self_link
  }

  network_interface {
    subnetwork    = google_compute_subnetwork.management-sub.self_link
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
    encrypt_key = var.encrypt_key
    data_center = var.data_center
    consul_join_tag = var.consul_join_tag
  }
}

output "rendered" {
  value = data.template_file.default.rendered
}


resource "google_storage_bucket_object" "consul-startup" {
  name   = "consul.hcl"
  //content = "${data.template_file.default.rendered}"
  source = "${path.module}/tmp/consul-startup.sh"
  bucket = "hashi-storage-bucket"
}

resource "local_file" "consul-startup" {
    content     = data.template_file.default.rendered
    filename = "${path.module}/tmp/consul-startup.sh"
}

data "google_compute_image" "debian_9" {
  family  = "debian-9"
  project = "debian-cloud"
}

data "google_compute_image" "centos_8" {
  family  = "centos-8"
  project = "centos-cloud"
}