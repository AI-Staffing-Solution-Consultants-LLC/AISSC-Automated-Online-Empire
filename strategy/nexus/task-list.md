# AISSC-Automated-Online-Empire — Phase 3 Task List

> Live backlog for Phase 3 (Build & Iterate). Every task feeds Dev↔QA loop validation rules and acceptance criteria.

| Task ID | Component | Description | Acceptance Criteria | Assigned Agent | QA Agent | Attempt | Status |
|---------|-----------|-------------|---------------------|----------------|----------|---------|--------|
| T1-SHERYL | Sheryl Gateway | Auth Finalization & Intent Router | Express OIDC validation, Cloud Tasks webhook dispatch, 403 enforcement for execution commands | Frontend / Gateway Dev | Evidence Collector | 0/3 | In Progress |
| T2-KRIEGER | Krieger Infrastructure | Systems & Secret Manager Integration | Google Secret Manager key loading, GCS FUSE mount hydration, Cloud Run container build verification | Backend Architect | Evidence Collector | 0/3 | Pending |
| T3-MALORY | Malory Ops | Business Ops & Compliance Layer | Compliance auditing rules, SLA P95 monitoring, audit trail log generation on dispatch | Workflow / Compliance Dev | Evidence Collector | 0/3 | Pending |
| T4-PAM | Pam Workforce | Workforce Dispatch & Telemetry | Hybrid task routing, Pub/Sub completion event fan-out, metric counter initialization | Systems Integrator | Evidence Collector | 0/3 | Pending |
| T5-KANBAN | Kanban Dashboard | Control Overlay & API Integration | Real-time `/status` polling, interactive `/dispatch` UI control overlay, responsive mobile/desktop HUD | UI/UX Developer | Evidence Collector | 0/3 | Pending |

## Execution Protocol & Rules
- **Max Retries**: 3 per task; attempt 3 failure triggers escalation to `Project Shepherd` (`strategy/nexus/handoffs/escalation.md`).
- **QA Verdicts**: Recorded in `strategy/nexus/handoffs/qa-pass.md` or `strategy/nexus/handoffs/qa-fail.md`.
- **Status Lifecycle**: Pending ──► In Progress ──► QA ──► Complete (or Escalated).
