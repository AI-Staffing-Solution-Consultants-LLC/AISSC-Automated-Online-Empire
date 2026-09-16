# NEXUS Phase 3 Component Sprint Plan

## Component Timeline & Schedule

| Sprint Phase | Component | Assigned Agent | Estimated Duration | Dependencies | Milestone Target |
|--------------|-----------|----------------|--------------------|--------------|------------------|
| Sprint 3.1 | **Sheryl Gateway** | Frontend / Gateway Dev | 4 Hours | Phase 2 Foundation | OIDC Auth validation, Intent Router, 403 Security Gate |
| Sprint 3.2 | **Krieger Infrastructure** | Backend Architect | 4 Hours | Sheryl Gateway | Secret Manager integration, GCS FUSE memory mount verification |
| Sprint 3.3 | **Malory Business Ops** | Workflow / Compliance Dev | 3 Hours | Krieger Infrastructure | Compliance audit rules, P95 SLA monitoring, audit logging |
| Sprint 3.4 | **Pam Workforce** | Systems Integrator | 3 Hours | Malory Business Ops | Hybrid task router, Pub/Sub completion event fan-out |
| Sprint 3.5 | **Kanban Dashboard** | UI/UX Developer | 2 Hours | Pam Workforce | Control overlay binding, real-time `/status` HUD display |

---

## Component Dependency Graph

```
           ┌────────────────────────┐
           │   Phase 2 Foundation   │
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │   T1: Sheryl Gateway   │
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │ T2: Krieger Infra      │
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │  T3: Malory Bus Ops    │
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │   T4: Pam Workforce    │
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │  T5: Kanban Dashboard  │
           └────────────────────────┘
```

---

## Component Success Metrics & Quality Gates

### 1. Sheryl Gateway (`T1-SHERYL`)
- **Metric**: `HTTP 200` on valid `/dispatch` payload; `HTTP 403` on unauthorized code execution attempt.
- **SLA**: Response time < 100ms.
- **QA Gate**: Pass OIDC token verification test and security gate assertion.

### 2. Krieger Infrastructure (`T2-KRIEGER`)
- **Metric**: Successful fetch of GSM keys & GCS FUSE mount detection (`/gs/aissc-persistent-memory-store`).
- **SLA**: Container cold start < 2.0s on Cloud Run.
- **QA Gate**: Verified non-root Node 18 container execution.

### 3. Malory Business Ops (`T3-MALORY`)
- **Metric**: Audit log record created per dispatch with zero budget/quota exceedances.
- **SLA**: P95 latency logging < 50ms overhead.
- **QA Gate**: Compliance check assertion output logged to telemetry.

### 4. Pam Workforce (`T4-PAM`)
- **Metric**: Pub/Sub task completion message published on topic `suad-task-completions`.
- **SLA**: Event fan-out latency < 150ms.
- **QA Gate**: Verified event receipt on test subscriber.

### 5. Kanban Dashboard (`T5-KANBAN`)
- **Metric**: Real-time status update rendering without UI layout shifts.
- **SLA**: HUD refresh rate 5s poll interval.
- **QA Gate**: Playwright viewport captures across Desktop (1920x1080), Tablet (768x1024), Mobile (375x667).

---

## Dev↔QA Feedback & Escalation Protocol

- **Attempt 1**: Developer builds component -> Evidence Collector runs tests.
- **Attempt 2**: If QA fails, `strategy/nexus/handoffs/qa-fail.md` is populated with specific failure traceback. Developer patches code.
- **Attempt 3**: Final QA re-test. If attempt 3 fails, task status changes to `Escalated` and notifies `Project Shepherd` (`strategy/nexus/handoffs/escalation.md`).
