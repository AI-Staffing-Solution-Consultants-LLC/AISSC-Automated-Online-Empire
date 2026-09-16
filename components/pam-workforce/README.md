# pam-workforce

Workforce orchestration and lead-generation workers for the AISSC fleet.

## Role

Pam owns the **workforce layer**: managing the deployable worker agents —
primarily **Barry**, the LobeHub-hosted lead-generation container — and their
schedules, priorities, and health.

## Active Worker: Barry (LobeHub)

| Attribute | Value |
|---|---|
| Priority | **LIVE before September 10** |
| Host | LobeHub container (currently running, port 8089, health OK) |
| Function | Lead generation for AI staffing services |
| Schedule | Fueled by Cloud Tasks `queue-krieger-inbox` dispatch, never self-loops |

### Barry Worker Manifest

```yaml
# components/pam-workforce/barry.manifest.yaml
worker: barry
host: lobehub
status: RUNNING            # target: DEPLOYED-Reconciled before Sep 10
priority: p0
deadline: 2026-09-10
function: lead-generation
inputs:
  - intent_dispatched (pubsub)
outputs:
  - lead_qualified (event, pubsub suad-task-completions)
dependencies:
  - litellm_proxy: https://suad-litellm-proxy-398899866173.us-east4.run.app/v1
  - model: gemini-flash
constraints:
  - no_self_modification
  - no_grant_filings_until_qa_pass
  - no_financial_commitments_until_qa_pass
```

## Worker Lifecycle

1. **Intake** — intent dispatched on the command bus (`queue-krieger-inbox`).
2. **Execute** — worker performs its task in an ephemeral context.
3. **Report** — completion/failure published on `suad-task-completions`.
4. **Retire** — worker returns to idle; no long-lived background loops.

## Files

- `barry.manifest.yaml` — authoritative Barry manifest (created next step)
- `README.md` — this file