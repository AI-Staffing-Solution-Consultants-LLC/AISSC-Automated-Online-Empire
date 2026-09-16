# GCP Log Router Sink & Telemetry Export Blueprint

This blueprint outlines the declarative configuration required to establish a zero-cost Google Cloud Logging Router Sink. It targets critical execution logs, application unhandled exceptions, and AI platform audit records, routing them securely via standard OIDC Pub/Sub bindings directly into your `AISSC-Automated-Online-Empire` monitoring pipelines.

---

## 1. Declarative Terraform Configuration (`logging-sink.tf`)

This module provisions the logging router sink, the target GCP Pub/Sub event topic, and grants the necessary least-privilege IAM permissions for the Logging service account to publish metrics.

```hcl
# ==============================================================================
# AISSC Automated Online Empire - Telemetry Ingestion Plane
# ==============================================================================

resource "google_pubsub_topic" "telemetry_event_topic" {
  name    = "aissc-telemetry-events"
  project = var.gcp_project_id

  labels = {
    business_unit = "aissc-automated-online-empire"
    environment   = "production"
    layer         = "observability"
  }
}

resource "google_logging_project_sink" "telemetry_logging_sink" {
  name        = "aissc-telemetry-sink"
  project     = var.gcp_project_id
  destination = "pubsub.googleapis.com/${google_pubsub_topic.telemetry_event_topic.id}"

  # Zero-Cost Logging Filter: captures only severity>=ERROR Cloud Run logs,
  # unhandled container stack traces, and Vertex AI prediction audit events.
  filter = <<EOF
(
  (resource.type = "cloud_run_revision" AND severity >= ERROR)
  OR
  (resource.type = "cloud_run_revision" AND (textPayload =~ "at " OR textPayload =~ "Traceback"))
  OR
  (resource.type = "audited_resource" AND logName =~ "logs/cloudaudit.googleapis.com" AND protoPayload.serviceName = "aiplatform.googleapis.com")
)
EOF

  # Exclude routine health probes or ping logs from ever triggering billing
  exclusions {
    name        = "exclude-routine-health-checks"
    description = "Excludes standard HTTP 200 GET health endpoints and wake pulses to conserve cost"
    filter      = "resource.type=\"cloud_run_revision\" AND (textPayload:\"GET /healthz\" OR textPayload:\"POST /wake\")"
  }

  unique_writer_identity = true
}

# Grant the Logging Sink Service Account permissions to publish into the Pub/Sub Topic
resource "google_pubsub_topic_iam_member" "sink_publisher_binding" {
  project = var.gcp_project_id
  topic   = google_pubsub_topic.telemetry_event_topic.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.telemetry_logging_sink.writer_identity
}
```

---

## 2. Zero-Cost Log Filter Specification

This filter is parsed natively within the Google Cloud log router engine. Because Log Routing is free of charge on Google Cloud, this configuration incurs **zero compute overhead or operational costs** to evaluate, ensuring your billing envelope remains flat at \$0.00.

### The Query String
```query
(
  (resource.type = "cloud_run_revision" AND severity >= ERROR)
  OR
  (resource.type = "cloud_run_revision" AND (textPayload =~ "at " OR textPayload =~ "Traceback"))
  OR
  (resource.type = "audited_resource" AND logName =~ "logs/cloudaudit.googleapis.com" AND protoPayload.serviceName = "aiplatform.googleapis.com")
)
```

### Breakdown of Ingested Log Classes

1. **Cloud Run Error States (`cloud_run_revision`)**: Tracks immediate execution crashes, standard runtime exit failures, and resource exhaustion triggers originating within `sheryl-gateway`, `krieger-tech-systems`, `pam-workforce`, or `malory-business-ops` containers.
2. **GCP Stack Traces (Regex Ingestion)**: Catches application stack trace patterns natively. By scanning for standard execution signatures like `"at "` (V8/Node engine layouts) or `"Traceback"` (Python/OpenClaw models), it isolates syntax or dependency issues.
3. **Vertex AI Gemini Audit Logs (`aiplatform.googleapis.com`)**: Gathers security audit records generated when models are queried, ensuring all interaction chains remain fully auditable and compliant under regional enterprise standards.

---

## 3. Local Workspace Remediation Integration

Once routed to Pub/Sub, the logs can be consumed in your workspace environment at `/home/josh/AISSC-Automated-Online-Empire/monitoring-telemetry-remediation/` to update your telemetry sink:

```
  [GCP Container Runtime]
             │
             ▼ (Writes to Stdout/Stderr)
  [GCP Cloud Logging Router] 
             │
             ▼ (Zero-Cost Logging Filter Matches)
  [GCP Cloud Pub/Sub Topic]
             │
             ▼ (Pushed / Pulled via headless CLI)
  [scripts/gcp-telemetry-bridge.mjs]
             │
             ▼ (Atomic Rename Renumeration)
  [gcp-telemetry.json (Sink)] ──► Registered in mcp-router-config.json
             │
             ▼ (Drift / Crash Detected)
  [Krieger Self-Remediation SUAD]
```

To execute a pull locally from your paired Antigravity IDE terminal without deploying Pub/Sub subscription workers, you can run this zero-cost lookup using the `gcloud` CLI directly:

```bash
gcloud logging read \
  '(resource.type = "cloud_run_revision" AND severity >= ERROR) OR (resource.type = "cloud_run_revision" AND (textPayload =~ "at " OR textPayload =~ "Traceback")) OR (resource.type = "audited_resource" AND logName =~ "logs/cloudaudit.googleapis.com" AND protoPayload.serviceName = "aiplatform.googleapis.com")' \
  --project="suad-claw-nexus-hybrid-01" \
  --limit=500 \
  --format="json" > /home/josh/AISSC-Automated-Online-Empire/monitoring-telemetry-remediation/gcp-telemetry.json
```
