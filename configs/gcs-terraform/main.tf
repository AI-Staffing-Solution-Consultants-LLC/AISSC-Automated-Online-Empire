# ==============================================================================
# AISSC Automated Online Empire - Persistent Memory Storage Plane (GCS)
# ==============================================================================
# Blueprint Origin: configs/gcs-terraform/main.tf
# ==============================================================================

resource "google_storage_bucket" "persistent_memory_store" {
  name                        = var.bucket_name
  location                    = var.region
  project                     = var.project_id
  storage_class               = "STANDARD"
  force_destroy               = false

  # Enforce Zero-Trust Unified IAM controls (deactivates legacy ACLs) [4]
  uniform_bucket_level_access = true

  # Block accidental public exposures to the global internet [4]
  public_access_prevention    = "enforced"

  # Retain historical backups, agent schemas, and operational memories [4]
  versioning {
    enabled = true
  }

  # Automatic Storage Class Optimization (FinOps Framework) [4]
  # Transition objects to NEARLINE storage class after 90 days of inactivity [4]
  lifecycle_rule {
    condition {
      age                   = 90
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Clean up or archive old telemetry/RAG snapshots older than 365 days [4]
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    business_unit = "aissc-automated-online-empire"
    environment   = "production"
    layer         = "memory-rag"
  }
}

# ==============================================================================
# Departmental Division of Authority (Scoped IAM Rules) [5]
# ==============================================================================

# 1. Krieger Lead Engineer: roles/storage.objectAdmin [6]
resource "google_storage_bucket_iam_member" "krieger_admin" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.krieger_service_account}"
}

# 2. Sheryl Gateway: roles/storage.objectViewer [6]
resource "google_storage_bucket_iam_member" "sheryl_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 3. Sheryl Gateway: roles/storage.objectCreator [6]
resource "google_storage_bucket_iam_member" "sheryl_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 4. Malory Operations: roles/storage.objectViewer [6]
resource "google_storage_bucket_iam_member" "malory_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.malory_service_account}"
}

# 5. Malory Operations: roles/storage.objectCreator
resource "google_storage_bucket_iam_member" "malory_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.malory_service_account}"
}

# 6. Pam Workforce: roles/storage.objectViewer
resource "google_storage_bucket_iam_member" "pam_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.pam_service_account}"
}

# 7. Pam Workforce: roles/storage.objectCreator
resource "google_storage_bucket_iam_member" "pam_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.pam_service_account}"
}
