// testing instance groups
resource "google_compute_region_autoscaler" "vault" {
  name   = "hashi-vault-region-autoscaler"
  //region = "us-central1"
  target = google_compute_region_instance_group_manager.vault.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "vault" {
  name           = "hashi-vault-instance-template"
  description    = "This template will be used to set up vault nodes"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["vault-member", "vault-cluster-node"]

  metadata_startup_script = data.template_file.vault.rendered
  disk {
    source_image = data.google_compute_image.centos_8.self_link
  }

  network_interface {
    subnetwork    = google_compute_subnetwork.management-sub.self_link
  }

  metadata = {
    name = "vault-server"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "vault" {
  name = "hashi-vault-target-pool"
}

resource "google_compute_region_instance_group_manager" "vault" {
  name   = "hashi-vault-region-igm"
  region = var.gcp_region

  version {
    instance_template  = google_compute_instance_template.vault.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.vault.id]
  base_instance_name = "hashi-vault"
  wait_for_instances = true
}

output "target_pools_members" {
  value = google_compute_target_pool.vault.instances
}

output "startup_script_rendered" "vault_output"{
  value = data.template_file.vault.rendered
}

data "template_file" "vault" {
  template = file("${path.module}/scripts/vault-config.tpl")
  vars = {
    vault_download_url = "releases.hashicorp.com/vault/${var.vault_version}/${var.vault_version}_linux_amd64.zip"
    consul_download_url = "releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip"
    encrypt_key = var.encrypt_key
    data_center = var.data_center
    consul_join_tag = var.consul_join_tag
  }
}

output "rendered" {
  value = data.template_file.vault.rendered
}

