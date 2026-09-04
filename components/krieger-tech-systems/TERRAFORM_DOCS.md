# Krieger Tech Systems: Infrastructure Specification

## Overview
Deploys the tactical infrastructure for `krieger-tech-systems` under SUAD scale-to-zero operational physics.

## Provisioned Resources
- **GCS FUSE Bucket (`suad-openviking-rag-${var.gcp_project_id}`):** Centralized knowledge base mounted directly to ephemeral runtimes to eliminate agent amnesia without persistent database costs.
- **Cloud Run Service (`krieger-tech-systems`):** Stateless execution worker configured with `--min-instances 0` and max concurrency of 5.
- **Cloud Tasks Queue (`queue-krieger-inbox`):** 1-to-1 command bus enforcing execution rate limits and temporal scheduling.
- **Pub/Sub Topic (`suad-task-completions`):** 1-to-Many event bus fanning out status receipts and telemetry updates.
- **Secret Manager IAM Binding:** Scopes access to `LITE_LLM_KEY` strictly to the Krieger Service Account.