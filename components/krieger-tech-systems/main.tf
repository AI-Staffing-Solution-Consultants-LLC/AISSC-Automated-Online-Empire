terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  krieger_image = var.suad_image != "" ? var.suad_image : "us-east4-docker.pkg.dev/${var.gcp_project_id}/nexus/krieger:latest"
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

# 1. OpenViking GCS FUSE Bucket - persistent shared memory across scale-to-zero cycles
resource "google_storage_bucket" "openviking_rag" {
  name                        = "suad-openviking-rag-${var.gcp_project_id}"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = false

  lifecycle {
    prevent_destroy = true
  }
}

# Storage Permissions for FUSE Mount
resource "google_storage_bucket_iam_member" "openviking_access" {
  bucket = google_storage_bucket.openviking_rag.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.krieger_sa.email}"
}

# 2. Scale-to-Zero Cloud Run Service with GCS FUSE Mount (strict SUAD physics)
resource "google_cloud_run_v2_service" "suad_service" {
  name     = "krieger-tech-systems"
  location = var.gcp_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

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
      image = local.krieger_image

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

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# 3. Google Cloud Tasks Command Bus (rate-limited, no sleep loops)
resource "google_cloud_tasks_queue" "command_bus" {
  name     = "queue-krieger-inbox"
  location = var.gcp_region

  rate_limits {
    max_dispatches_per_second = 3
    max_concurrent_dispatches = 2
  }

  retry_config {
    max_attempts = 3
  }
}

# 4. Google Cloud Pub/Sub Event Bus (1-to-Many task completion fan-out)
resource "google_pubsub_topic" "event_bus" {
  name = "suad-task-completions"

  message_retention_duration = "86400s"
}

# 5. Secret Manager IAM Binding - LITE_LLM_KEY scoped strictly to Krieger SA
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = "LITE_LLM_KEY"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.krieger_sa.email}"
}