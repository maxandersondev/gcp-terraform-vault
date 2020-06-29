resource "google_compute_network" "management" {
  name = "hashi-managment-network"
  auto_create_subnetworks = "false"
}

/*
resource "google_compute_network" "trust" {
  name                    = "hashi-trust-network"
  auto_create_subnetworks = "false"
}
*/
// Adding VPC Networks to Project  MANAGEMENT
resource "google_compute_subnetwork" "management-sub" {
  name          = "management-sub"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.management.self_link
  region        = var.gcp_region
}

// Adding VPC Networks to Project  TRUST
/*resource "google_compute_subnetwork" "trust-sub" {
  name          = "trust-sub"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.trust.self_link
  region        = var.gcp_region
}
*/


resource "google_compute_firewall" "default" {
  name    = "management-firewall"
  network = google_compute_network.management.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "8080", "1000-2000", "8000-8601"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["8301", "8302", "8000-8601"]
  }

  source_ranges = ["0.0.0.0/0"]
  //source_tags = ["web"]
}
/*
// Adding GCP Firewall Rules for OUTBOUND
resource "google_compute_firewall" "allow-outbound" {
  name    = "allow-outbound"
  network = google_compute_network.trust.self_link
  direction = "EGRESS"
  allow {
    protocol = "all"

    # ports    = ["all"]
  }

  //source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-inbound" {
  name    = "trust-allow-inbound"
  network = google_compute_network.trust.self_link
  
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "1000-2000"]
  }

  source_ranges = ["10.0.2.0/24"]
}
*/
resource "google_compute_router" "hashi-router" {
  name    = "hashi-router"
  region  = google_compute_subnetwork.management-sub.region
  network = google_compute_network.management.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "hashi-nat" {
  name                               = "hashi-router-nat"
  router                             = google_compute_router.hashi-router.name
  region                             = google_compute_router.hashi-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
