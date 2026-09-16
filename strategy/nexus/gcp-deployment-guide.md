# GCP Infrastructure Deployment Guide & Phase 3 Readiness Checklist

## GCP Project Boundaries
- **Project ID**: `suad-claw-nexus-hybrid-01`
- **Region**: `us-central1` (Primary) / `us-east4` (Messaging Queues)
- **Central Storage**: `gs://aissc-persistent-memory-store`

---

## 1. Prerequisites Verification Checklist

- [x] **Google Cloud CLI**: Authenticated (`gcloud auth application-default login`)
- [x] **Required APIs Enabled**:
  - `aiplatform.googleapis.com`
  - `generativelanguage.googleapis.com`
  - `run.googleapis.com`
  - `cloudtasks.googleapis.com`
  - `pubsub.googleapis.com`
  - `secretmanager.googleapis.com`
  - `storage.googleapis.com`
- [x] **Service Accounts Provisioned**:
  - Krieger: `krieger-tech-systems@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com`
  - Sheryl: `sheryl-gateway@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com`
  - Malory: `malory-business-ops@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com`
  - Pam: `pam-workforce@suad-claw-nexus-hybrid-01.iam.gserviceaccount.com`

---

## 2. Infrastructure Provisioning Deployment Steps

### Step 1: Deploy Terraform Persistent Storage
```bash
cd /home/josh/AISSC-Automated-Online-Empire/configs/gcs-terraform

# 1. Initialize Terraform
terraform init

# 2. Plan deployment
terraform plan -out=tfplan.binary

# 3. Apply infrastructure
terraform apply tfplan.binary
```

### Step 2: Configure Cloud Tasks Queues & Pub/Sub Topics
```bash
cd /home/josh/AISSC-Automated-Online-Empire/configs/cloud-tasks-setup

# 1. Create Cloud Tasks Command Queue
gcloud tasks queues create queue-krieger-inbox \
  --location=us-east4 \
  --max-dispatches-per-second=3 \
  --max-concurrent-dispatches=2

# 2. Create Pub/Sub Event Bus Topic
gcloud pubsub topics create suad-task-completions
```

### Step 3: Build & Deploy Container to Cloud Run
```bash
cd /home/josh/AISSC-Automated-Online-Empire

# 1. Submit build to Cloud Build / Artifact Registry
gcloud builds submit --tag gcr.io/suad-claw-nexus-hybrid-01/aissc-core-service:latest .

# 2. Deploy Cloud Run SUAD Micro-Runtime
gcloud run deploy aissc-core-service \
  --image gcr.io/suad-claw-nexus-hybrid-01/aissc-core-service:latest \
  --region us-central1 \
  --platform managed \
  --min-instances 0 \
  --max-instances 5 \
  --no-cpu-throttling \
  --allow-unauthenticated \
  --set-env-vars="ACTIVE_AGENT_PROFILE=sheryl,MEMORY_MOUNT_PATH=/gs/aissc-persistent-memory-store"
```

---

## 3. Phase 3 Readiness Checklist

| Category | Requirement | Status | Verification Reference |
|----------|-------------|--------|------------------------|
| **Terraform** | Persistent GCS Bucket configs defined | ✅ READY | `configs/gcs-terraform/main.tf` |
| **Server Code** | Express Runtime & Security Middleware | ✅ READY | `server.mjs` |
| **Container** | Non-root slim Node 18 Dockerfile | ✅ READY | `Dockerfile` |
| **MCP Router** | Registered tools & Task queue bindings | ✅ READY | `mcp/mcp-router-config.json` |
| **Gate Check** | Phase 2 Passed Audit Certificate | ✅ READY | `strategy/nexus/gate-check.md` |
| **Task List** | Phase 3 Component Task Backlog | ✅ READY | `strategy/nexus/task-list.md` |
| **Sprint Plan** | Component Schedule & Dependencies | ✅ READY | `strategy/nexus/sprint-plan.md` |
| **Status Report**| Phase 3 Active Tracking | ✅ READY | `strategy/nexus/status-report.md` |
