# Create a KMS key ring
resource "google_kms_key_ring" "key_ring" {
   project  = "${var.gcp_project_id}"
   name     = "${var.key_ring}"
   location = "${var.keyring_location}"
}

# Create a crypto key for the key ring
resource "google_kms_crypto_key" "crypto_key" {
   name            = "${var.crypto-key}"
   key_ring        = "${google_kms_key_ring.key_ring.self_link}"
   rotation_period = "100000s"
}