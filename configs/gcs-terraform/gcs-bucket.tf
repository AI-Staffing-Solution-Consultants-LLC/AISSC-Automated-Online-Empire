# ==============================================================================
# AISSC Automated Online Empire - Persistent Memory Storage Plane (GCS)
# ==============================================================================
# This declarative HCL blueprint configures the central GCS bucket used as the
# stateless shared-memory plane (OpenViking RAG database layer) for the SUAD system.
#
# Target File Path: /home/josh/AISSC-Automated-Online-Empire/gcs-terraform/blueprints/gcs-bucket.tf
# ==============================================================================

# Central Storage Bucket Definition
resource "google_storage_bucket" "persistent_memory_store" {
  name                        = var.bucket_name
  location                    = var.region
  project                     = var.project_id
  storage_class               = "STANDARD"
  force_destroy               = false

  # Enforce Zero-Trust Unified IAM controls (deactivates legacy ACLs) [91, 140, 189, 249, 298, 304, 383]
  uniform_bucket_level_access = true

  # Block accidental public exposures to the global internet [91, 140, 189, 249, 298, 304, 383]
  public_access_prevention    = "enforced"

  # Retain historical backups, agent schemas, and operational memories [91, 140, 189, 249, 298, 304, 383]
  versioning {
    enabled = true
  }

  # Automatic Storage Class Optimization (FinOps Framework) [91, 140, 189, 249, 298, 304, 383]
  # Transition objects to NEARLINE storage class after 90 days of inactivity
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

  # Clean up or archive old telemetry/RAG snapshots older than 365 days
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
# Departmental Division of Authority (Scoped IAM Rules) [92, 98, 141, 147, 190, 196, 250, 256, 299, 305, 384, 386]
# ==============================================================================

# 1. Krieger Lead Engineer: roles/storage.objectAdmin [93, 99, 142, 148, 191, 197, 251, 257, 300, 306, 385, 387]
# Authorizes directory structures, database migration execution, and RAG template modification
resource "google_storage_bucket_iam_member" "krieger_admin" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.krieger_service_account}"
}

# 2. Sheryl Gateway: roles/storage.objectViewer [93, 99, 142, 148, 191, 197, 251, 257, 300, 306, 385, 387]
# Authorizes reading of operational runbooks and schemas
resource "google_storage_bucket_iam_member" "sheryl_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 3. Sheryl Gateway: roles/storage.objectCreator [93, 99, 142, 148, 191, 197, 251, 257, 300, 306, 385, 387]
# Authorizes writing of incoming Telegram user session buffers and ingestion tasks
resource "google_storage_bucket_iam_member" "sheryl_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 4. Malory Operations: roles/storage.objectViewer only [93, 99, 142, 148, 191, 197, 251, 257, 300, 306, 385, 387]
# Authorizes analysis of compliance audits, system telemetry metrics, and financial ledger check logs
resource "google_storage_bucket_iam_member" "malory_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.malory_service_account}"
}

# ==============================================================================
# Variable Declarations (Prevents Hardcoded Drift) [100, 143, 192, 252, 258, 301, 307]
# ==============================================================================

variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID"
  default     = "suad-claw-nexus-hybrid-01"
}

variable "region" {
  type        = string
  description = "The target GCP Regional zone"
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  description = "Central persistent shared memory store bucket name"
  default     = "aissc-persistent-memory-store"
}

variable "krieger_service_account" {
  type        = string
  description = "Systems Tech division service account email"
  default     = "krieger-tech-systems@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "sheryl_service_account" {
  type        = string
  description = "Chief Temporal Gateway division service account email"
  default     = "sheryl-gateway@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}

variable "malory_service_account" {
  type        = string
  description = "Business Operations division service account email"
  default     = "malory-business-ops@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}
