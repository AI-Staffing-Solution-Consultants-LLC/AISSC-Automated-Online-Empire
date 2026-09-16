# krieger-tech-systems

Tactical SUAD (Spin-Up-And-Die) execution layer for AISSC.

## Role

Krieger owns the **action layer**: stateless infrastructure execution, and the
headless Ouroboros terminal. It receives commands on the Cloud Tasks command
bus, executes infrastructure work, and publishes completion events on Pub/Sub.

## Provisioned Infrastructure (Terraform)

| Resource | Type | Purpose |
|---|---|---|
| `suad-openviking-rag-<project>` | GCS bucket (FUSE) | Persistent shared memory across scale-to-zero cycles |
| `krieger-tech-systems` | Cloud Run v2 service | Scale-to-zero worker: `min 0 / max 5`, 1000m CPU, 512Mi mem, GCS FUSE at `/mnt/openviking` |
| `queue-krieger-inbox` | Cloud Tasks queue | 1-to-1 command bus: 3 dispatches/sec, max 2 concurrent |
| `suad-task-completions` | Pub/Sub topic | 1-to-Many completion event fan-out |
| `LITE_LLM_KEY` accessor | Secret Manager IAM | Scoped strictly to the Krieger service account |

## SUAD Physics

- `min_instance_count = 0` — zero idle spend; every instance dies when idle.
- Stateless containers; durable state lives in the OpenViking GCS FUSE mount
  (gen2 execution environment, GCS FUSE available).
- No sleep loops: rate limits on the command bus enforce pacing, not polling.

## Usage

```bash
cd components/krieger-tech-systems
terraform init
terraform validate
terraform plan -var="gcp_project_id=suad-claw-nexus-hybrid-01"
# terraform apply ONLY through the gated CI/CD pipeline after QA passes
```

## Files

- `main.tf` — resources (bucket, Cloud Run, queue, topic, IAM)
- `variables.tf` — `gcp_project_id`, `gcp_region` (default `us-east4`), `suad_image`
- `outputs.tf` — bucket, service URL, queue, topic, service account email
- `TERRAFORM_DOCS.md` — infrastructure specification narrative