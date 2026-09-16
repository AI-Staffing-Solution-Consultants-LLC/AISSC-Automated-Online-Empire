# AISSC Eventarc Trigger Specification: Closed-Loop Remediation

This specification defines the Google Cloud Eventarc routing configuration designed to automatically capture critical failure notifications from your logging Pub/Sub event bus (`aissc-telemetry-events`) and dispatch them natively to the **Krieger Tech Systems** Cloud Run micro-runtime.

This event-driven linkage establishes a closed-loop autonomous remediation cycle: when standard logging router sinks catch high-severity errors (`severity >= ERROR`), they publish a message that invokes Krieger to execute corrective scripts without any human intervention.

---

## 1. Remediation Architecture Flow

```
   [GCP Cloud Run Service] (Enters ERROR State)
              │
              ▼
    [Cloud Logging Router Sink]
              │
      (Filters Out Errors)
              │
              ▼
   [Pub/Sub Telemetry Topic] (`aissc-telemetry-events`)
              │
              ▼
   [Eventarc Trigger] (OIDC Authenticated Transport)
              │
              ▼
 [Krieger Tech Systems Cloud Run] (Dynamic Remediation Run)
```

1. **Ingress Event**: Any micro-runtime container experiencing an unhandled exception or critical error logs its output to standard stdout/stderr, which is captured by Cloud Logging.
2. **Filtering**: The Cloud Logging Sink filters this log and publishes the error signature to the `aissc-telemetry-events` Pub/Sub topic.
3. **Dispatch**: The Eventarc Trigger detects the message, extracts the payload, negotiates an OIDC authentication token, and executes an HTTP POST request targeting `/remediate` on the Krieger service.
4. **Execution**: Krieger boots up instantly from zero, mounts your shared `aissc-persistent-memory-store` GCS bucket, matches the error signature to an active remediation playbook, runs the fix (such as scaling, recycling keys, or running Terraform patches), and terminates.

---

## 2. Dynamic Eventarc Trigger Resource Definitions

You can implement this Eventarc configuration using either the Google Cloud CLI (`gcloud`) or declaratively via Terraform.

### Option A: Declarative Terraform Configuration

Add this resource block to your main infrastructure setup in your `/home/josh/AISSC-Automated-Online-Empire/gcs-terraform/` configuration files:

```hcl
# Create the Service Account used by Eventarc to invoke Cloud Run securely
resource "google_service_account" "eventarc_trigger_sa" {
  account_id   = "aissc-eventarc-trigger-sa"
  display_name = "AISSC Eventarc Trigger Service Account"
  project      = var.project_id
}

# Grant Eventarc permissions to invoke your specific Cloud Run service
resource "google_cloud_run_service_iam_member" "eventarc_run_invoker" {
  service  = "krieger-tech-systems"
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.eventarc_trigger_sa.email}"
}

# Grant pubsub.subscriber role to the Eventarc service agent
resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

# Define the Eventarc Trigger routing resource
resource "google_eventarc_trigger" "telemetry_error_trigger" {
  name     = "aissc-telemetry-error-trigger"
  location = var.region
  project  = var.project_id

  # Transport definition using the Pub/Sub topic created by the logging sink
  transport {
    pubsub {
      topic = "projects/${var.project_id}/topics/aissc-telemetry-events"
    }
  }

  # Filter match criteria
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  # Route destination configurations
  destination {
    cloud_run_service {
      service = "krieger-tech-systems"
      region  = var.region
      path    = "/remediate"
    }
  }

  service_account = google_service_account.eventarc_trigger_sa.email

  labels = {
    business_unit = "aissc-automated-online-empire"
    environment   = "production"
  }

  depends_on = [
    google_cloud_run_service_iam_member.eventarc_run_invoker,
    google_project_iam_member.pubsub_subscriber
  ]
}
```

### Option B: Unified Google Cloud CLI Command

To manually register the Eventarc trigger from your Antigravity IDE terminal workspace, execute the following command:

```bash
gcloud eventarc triggers create aissc-telemetry-error-trigger \
    --project="suad-claw-nexus-hybrid-01" \
    --location="us-central1" \
    --destination-run-service="krieger-tech-systems" \
    --destination-run-path="/remediate" \
    --destination-run-region="us-central1" \
    --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
    --transport-topic="projects/suad-claw-nexus-hybrid-01/topics/aissc-telemetry-events" \
    --service-account="aissc-eventarc-trigger-sa@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com"
```

---

## 3. Remediator Payload Integration Contracts

When the Eventarc trigger invokes `/remediate` on the Krieger Tech Systems micro-runtime, it packages the incoming Pub/Sub message within a standardized CloudEvents JSON envelope. 

Krieger's parser expects the following incoming JSON schema payload structure:

```json
{
  "specversion": "1.0",
  "id": "eventarc-unique-identifier-guid",
  "source": "//cloudevents.googleapis.com/projects/suad-claw-nexus-hybrid-01/topics/aissc-telemetry-events",
  "type": "google.cloud.pubsub.topic.v1.messagePublished",
  "datacontenttype": "application/json",
  "time": "2026-09-05T19:00:00.000Z",
  "data": {
    "message": {
      "data": "eyAiaW5zZXJ0SWQiOiAiMTAyOTM4NDciLCAidGltZXN0YW1wIjogIjIwMjYtMDktMDVUMTk6MDA6MDBaIiwgInNldmVyaXR5IjogIkVSUk9SIiwgInRleHRQYXlsb2FkIjogIklkZW1wb3RlbmN5IGtleSBjb25mbGljdDogZHVwbGljYXRlIHdyaXRlIGRldGVjdGVkIGluIHNlcnZlci5tanMiIH0=",
      "messageId": "1192837498172387",
      "publishTime": "2026-09-05T19:00:01.000Z"
    }
  }
}
```

### Payload Structure Breakdown:
* **`data.message.data`**: This contains the base64-encoded standard output log originating from your failed container. Decoding this payload yields:
  ```json
  {
    "insertId": "10293847",
    "timestamp": "2026-09-05T19:00:00Z",
    "severity": "ERROR",
    "textPayload": "Idempotency key conflict: duplicate write detected in server.mjs"
  }
  ```
* **Authentication Header**: Eventarc will append an authorization header containing the temporary OpenID Connect (OIDC) identity token of the runner:
  ```http
  Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6Ii...
  ```
  Krieger's system uses its native `jose` middleware to verify this claim against Google's public JWKS certificates before processing the fix.
