resource "google_storage_bucket" "startup-scripts" {
  name          = "hashi-storage-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = "3"
    }
    action {
      type = "Delete"
    }
  }
}