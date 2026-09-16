# ==============================================================================
# AISSC Automated Online Empire - Persistent Memory Storage Plane (GCS) - V2
# ==============================================================================
# This declarative HCL blueprint configures the central GCS bucket used as the
# stateless shared-memory plane (OpenViking RAG database layer) for the SUAD system.
# It enforces strict IAM access roles restricted to Sheryl, Krieger, Pam, and Malory.
#
# Target File Path: /home/olly/AISSC-Automated-Online-Empire/gcs-terraform/blueprints/gcs-bucket-v2.tf
# ==============================================================================

# Central Storage Bucket Definition
resource "google_storage_bucket" "persistent_memory_store" {
  name                        = var.bucket_name
  location                    = var.region
  project                     = var.project_id
  storage_class               = "STANDARD"
  force_destroy               = false

  # Enforce Zero-Trust Unified IAM controls (deactivates legacy ACLs)
  uniform_bucket_level_access = true

  # Block accidental public exposures to the global internet
  public_access_prevention    = "enforced"

  # Retain historical backups, agent schemas, and operational memories
  versioning {
    enabled = true
  }

  # Automatic Storage Class Optimization (FinOps Framework)
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
# Departmental Division of Authority (Scoped IAM Rules)
# ==============================================================================

# 1. Krieger Lead Engineer: roles/storage.objectAdmin
# Authorizes directory structures, database migration execution, and RAG template modification
resource "google_storage_bucket_iam_member" "krieger_admin" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.krieger_service_account}"
}

# 2. Sheryl Gateway: roles/storage.objectViewer
# Authorizes reading of operational runbooks and schemas
resource "google_storage_bucket_iam_member" "sheryl_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 3. Sheryl Gateway: roles/storage.objectCreator
# Authorizes writing of incoming Telegram user session buffers and ingestion tasks
resource "google_storage_bucket_iam_member" "sheryl_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.sheryl_service_account}"
}

# 4. Malory Operations: roles/storage.objectViewer
# Authorizes reading of compliance audits, system telemetry metrics, and financial ledger check logs
resource "google_storage_bucket_iam_member" "malory_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.malory_service_account}"
}

# 5. Malory Operations: roles/storage.objectCreator
# Authorizes writing of compiled analytics reports, executive summaries, and system logs back to the shared store
resource "google_storage_bucket_iam_member" "malory_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.malory_service_account}"
}

# 6. Pam Workforce: roles/storage.objectViewer
# Authorizes reading of workload routing tables, available task rosters, and persistent agent configurations
resource "google_storage_bucket_iam_member" "pam_viewer" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.pam_service_account}"
}

# 7. Pam Workforce: roles/storage.objectCreator
# Authorizes writing of web scraping results, dispatch state snapshots, and LobeHub session buffers
resource "google_storage_bucket_iam_member" "pam_creator" {
  bucket = google_storage_bucket.persistent_memory_store.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.pam_service_account}"
}

# ==============================================================================
# Variable Declarations (Prevents Hardcoded Drift)
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

variable "pam_service_account" {
  type        = string
  description = "Workforce Dispatch division service account email"
  default     = "pam-workforce@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
}
