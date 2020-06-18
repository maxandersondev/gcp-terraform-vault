resource "google_compute_network" "managment" {
  name = "hashi-managment-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_network" "trust" {
  name                    = "hashi-trust-network"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  MANAGEMENT
resource "google_compute_subnetwork" "management-sub" {
  name          = "management-sub"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.managment.self_link
  region        = var.gcp_region
}

// Adding VPC Networks to Project  TRUST
resource "google_compute_subnetwork" "trust-sub" {
  name          = "trust-sub"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.trust.self_link
  region        = var.gcp_region
}


resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.managment.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "8080", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]
  //source_tags = ["web"]
}

// Adding GCP Firewall Rules for OUTBOUND
resource "google_compute_firewall" "allow-outbound" {
  name    = "allow-outbound"
  network = "${google_compute_network.trust.self_link}"

  allow {
    protocol = "all"

    # ports    = ["all"]
  }

  source_ranges = ["0.0.0.0/0"]
}
