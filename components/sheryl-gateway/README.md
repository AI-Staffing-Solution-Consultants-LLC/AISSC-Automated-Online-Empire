# sheryl-gateway

External ingress router and control-plane entrypoint for the AISSC fleet.

## Role

Sheryl is the **gateway agent** — she owns the external surface of the system:

- **Telegram webhook endpoint** (`POST /telegram-webhook`) — receives messages,
  parses intent, and relays to the LLM proxy for response generation.
- **MCP router entrypoint** — registered in `mcp-router-config.json` (repo root)
  as the `sheryl-gateway` HTTP tool, inbound from the agency runtime.
- **Zero-execution privilege** — the gateway never executes tasks, runs Terraform,
  or mutates infrastructure. It only parses, routes, and dispatches to the
  action layer (Krieger / PAM workforce) via Cloud Tasks.

## Security Posture

| Concern | Posture |
|---|---|
| Privilege | Zero-execution; no IAM beyond Cloud Run invoker access |
| Secrets | Read from Google Secret Manager via runtime env; never logged |
| Memory | GCS bucket (`suad-sheryl-memory-*`) for system memory + per-chat sessions |
| Auth | OIDC identity (`sheryl-gateway@…iam.gserviceaccount.com`), `roles/run.invoker` |

## Files

- `app.js` — Express gateway (mirror of the running deployment, non-destructive reference)
- `package.json` — dependencies (`express`, `axios`, `@google-cloud/storage`, `dotenv`)

## Deploy

Deployed via the matrix CI/CD pipeline (`.github/workflows/ci-cd-main.yml`,
`deploy-apps` job) as a Cloud Run service.

> **Safety note:** the running production container is NOT mutated by this repo.
> This component is the reconciliation copy; deployment happens only through the
> gated CI/CD workflow after QA passes.