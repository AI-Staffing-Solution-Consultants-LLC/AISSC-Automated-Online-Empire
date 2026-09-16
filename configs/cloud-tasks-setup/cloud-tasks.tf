

# Create the secure Cloud Tasks Command Bus Queue for B2B Lead Gen operations
resource "google_cloud_tasks_queue" "b2b_lead_gen_queue" {
  name     = "b2b-lead-gen-queue"
  location = "us-central1"
  project  = var.project_id

  # Rate-limiting parameters protecting endpoints from traffic spikes
  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 5 # Enforces strict concurrency ceiling
  }

  # Hard retry caps preventing billing runaways
  retry_config {
    max_attempts       = 3   # Drops task on 3rd failure to trigger remediation
    min_backoff        = "5s"  # Base delay
    max_backoff        = "300s" # 5-minute maximum penalty delay
    max_doublings      = 4
  }

  # Configures standard telemetry streaming to Cloud Logging
  stackdriver_logging_config {
    sampling_ratio = 1.0 # Write 100% of task trace data
  }

  # Points to a custom Dead-Letter Destination (Pub/Sub alert topic)
  # When a task breaches its 3-attempt limit, it notifies Krieger's remediation endpoint
  depends_on = [
    google_pubsub_topic.remediation_alerts
  ]
}

# The target Pub/Sub alerting topic used as a Dead-Letter Queue (DLQ) boundary
resource "google_pubsub_topic" "remediation_alerts" {
  name    = "aissc-telemetry-events"
  project = var.project_id
}

# Variables mapping parameters to infrastructure runs
variable "project_id" {
  type        = string
  default     = "suad-claw-nexus-hybrid-01"
  description = "The target Google Cloud Project ID"
}

