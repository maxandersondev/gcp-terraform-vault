// Configure the Google Cloud provider
provider "google" {
 region      = "us-central1"
 project     = "hashi-project"
}
/*
// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
 name         = "hashi-consul-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-west1-a"

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }

// Make sure flask is installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask"

 network_interface {
   network = "default"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }
}
*/
// testing instance groups
resource "google_compute_region_autoscaler" "foobar" {
  name   = "hashi-vault-region-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.foobar.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "foobar" {
  name           = "hashi-vault-instance-template"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["foo", "bar"]

  disk {
    source_image = data.google_compute_image.debian_9.self_link
  }

  network_interface {
    network = "default"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "foobar" {
  name = "hashi-vault-target-pool"
}

resource "google_compute_region_instance_group_manager" "foobar" {
  name   = "hashi-vault-region-igm"
  region = "us-central1"

  version {
    instance_template  = google_compute_instance_template.foobar.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.foobar.id]
  base_instance_name = "foobar"
}

data "google_compute_image" "debian_9" {
  family  = "debian-9"
  project = "debian-cloud"
}