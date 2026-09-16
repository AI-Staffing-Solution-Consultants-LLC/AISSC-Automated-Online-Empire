# malory-business-ops

Business logic, analytics, and schema-compliance layer for the AISSC fleet.

## Role

Malory owns the **business layer**: revenue reconciliation, lead scoring,
conversion analytics, and schema compliance for commercial operations. Every
event published on the `suad-task-completions` Pub/Sub topic can be aggregated
here into business KPIs.

## Scope

- Reconcile operational telemetry (`gcp-telemetry.json`) against business events.
- Track pipeline health: leads → contacts → qualified opportunities → revenue.
- Schema compliance for all handoff documents (`handoffs/`, `strategy/nexus/`).
- **Deferred until QA gate passes**: grant filings, external financial
  commitments, and any real-world payout actions.

## Event Schema (Contract)

Every task-completion event published to Pub/Sub MUST conform to:

```json
{
  "event_id": "uuid-v4",
  "event_type": "task_complete | task_failed | intent_dispatched",
  "source_service": "krieger | sheryl | barry | malory",
  "task_id": "string",
  "occurred_at": "RFC-3339 UTC",
  "idempotency_key": "required-for-dlq-safe-retries",
  "payload": {}
}
```

Rules:

- `idempotency_key` is REQUIRED on every event (duplicate detection in the DLQ).
- FIFO ordering is preserved per `task_id`; out-of-order events must be flagged.
- Events older than the sink retention window (1 day) are dropped by the bridge.

## Integration

- Reads: `../../gcp-telemetry.json` (error telemetry), Pub/Sub topic
  `suad-task-completions` (business events).
- Writes: `../../strategy/nexus/handoffs/` readiness reports, KPI summaries.

## Deferred (per directive)

Grant submissions, commercial payouts, and financial commitments are HELD until
`strategy/nexus/handoffs/qa-pass.md` exists with passing evidence.