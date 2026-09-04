terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "gcp_project_id" {
  type        = string
  description = "Target Google Cloud Project ID"
}

variable "gcp_region" {
  type        = string
  description = "Default GCP Region"
  default     = "us-central1"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Dedicated Department Service Account
resource "google_service_account" "krieger_sa" {
  account_id   = "krieger-tech-systems"
  display_name = "Krieger Tech Systems SUAD Runner"
}

# 1. GCS Bucket for OpenViking RAG Memory
resource "google_storage_bucket" "openviking_rag" {
  name                        = "suad-openviking-rag-${var.gcp_project_id}"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = false
}

# Storage Permissions for FUSE Mount
resource "google_storage_bucket_iam_member" "openviking_access" {
  bucket = google_storage_bucket.openviking_rag.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.krieger_sa.email}"
}

# 2. Cloud Run Service with SUAD Scale-to-Zero and GCS FUSE Mount
resource "google_cloud_run_v2_service" "suad_service" {
  name     = "krieger-tech-systems"
  location = var.gcp_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    service_account = google_service_account.krieger_sa.email

    volumes {
      name = "openviking-brain"
      gcs {
        bucket    = google_storage_bucket.openviking_rag.name
        read_only = false
      }
    }

    containers {
      image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/nexus/krieger:latest"

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      volume_mounts {
        name       = "openviking-brain"
        mount_path = "/mnt/openviking"
      }

      env {
        name  = "OPENVIKING_MOUNT_DIR"
        value = "/mnt/openviking"
      }

      env {
        name  = "GCP_PROJECT_ID"
        value = var.gcp_project_id
      }
    }
  }
}

# 3. Cloud Tasks Queue (Command Bus)
resource "google_cloud_tasks_queue" "command_bus" {
  name     = "queue-krieger-inbox"
  location = var.gcp_region

  rate_limits {
    max_dispatches_per_second = 3
    max_concurrent_dispatches = 2
  }
}

# 4. Pub/Sub Topic (Event Bus)
resource "google_pubsub_topic" "event_bus" {
  name = "suad-task-completions"
}

# 5. Secret Manager IAM Binding for OIDC Service Accounts
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = "LITE_LLM_KEY"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.krieger_sa.email}"
}