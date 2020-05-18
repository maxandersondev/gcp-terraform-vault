// Configure the Google Cloud provider
provider "google" {
 region      = "us-west1"
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
data "google_compute_image" "my_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix  = "instance-template-"
  machine_type = "n1-standard-1"
  region       = "us-central1"

  // boot disk
  disk {
    source_image = google_compute_image.my_image.self_link
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.instance_template.self_link
  base_instance_name = "instance-group-manager"
  zone               = "us-central1-f"
  target_size        = "2"
}