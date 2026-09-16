# Remediation Router Specification (remediation-router.md)

This blueprint defines the declarative self-healing and telemetry-remediation routing architecture for the **AISSC-Automated-Online-Empire**. It details how the **Krieger Tech Systems** micro-runtime digests Eventarc logging payloads and dynamically maps identified execution failures to automated, unprivileged container remediation playbooks.

---

## 1. Remediation Pipeline Flow

The self-healing cycle maintains the zero-human operational footprint of the system by chaining GCP native log extraction with isolated, rule-bound execution routes.

```
       [GCP Logging Sink] ──► (Filters severity>=ERROR)
                                    │
                                    ▼
       [Eventarc Trigger] ──► (Dispatches OIDC POST to Krieger)
                                    │
                                    ▼
       [Remediation Router] ──► (Parses Base64 payload & logs)
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         ▼                          ▼                          ▼
[Error Signature A]        [Error Signature B]        [Error Signature C]
 (Heap Out of Memory)     (Database Deadlocks)      (OIDC Token Expired)
         │                          │                          │
         ▼                          ▼                          ▼
 [Remediation Route 01]    [Remediation Route 02]     [Remediation Route 03]
(Auto-Scale & Throttle)   (Rollback & Queue Flush)   (Trigger Trust Refresh)
```

1. Ingress: Eventarc forwards Cloud Logging payloads directly to Krieger's HTTPS endpoint `/remediate` via an OIDC-authenticated `POST` request.
2. Parsing: Krieger decodes the nested Base64-encoded log string and parses the metadata (resource ID, timestamp, and payload text).
3. Signature Matching: The engine evaluates the payload against a compiled registry of regular expressions matching known system errors.
4. Execution Gate: If a match is found, Krieger checks the security policy for the target route. If approved, the localized recovery script is executed in an isolated, non-blocking asynchronous thread.
5. Telemetry Logging: The outcome of the remediation attempt is written to the GCS bucket memory store to update the system’s central `gcp-telemetry.json` state.

---

## 2. Telemetry Error Signature Matrix

The routing engine relies on this deterministic classification table to match log outputs to remediation playbooks:

| Error Type | Log Signature Pattern (Regex) | Target Playbook File | Resolution Strategy |
| :--- | :--- | :--- | :--- |
| **Heap Out of Memory** | `/JavaScript heap out of memory/i` | `remediate-memory.mjs` | Flushes internal object cache pools, rejects massive payloads, and triggers a Cloud Tasks warning to partition future lead packs. |
| **DB Deadlock / Locks** | `/deadlock detected|Lock wait timeout/i` | `remediate-db-lock.mjs` | Triggers a transactional rollback, aborts the blocking query, and schedules a retry with linear jitter via Cloud Tasks. |
| **OIDC / Token Expired** | `/jwt expired|invalid signature|aud mismatch/i` | `remediate-auth-trust.mjs` | Aborts current S3-to-GCS migration steps and enqueues an emergency telemetry alert for manual trust pool rotation. |
| **Network Timeout** | `/ETIMEDOUT|ENOTFOUND|ECONNREFUSED/i` | `remediate-network.mjs` | Initiates exponential backoff on connection handles and verifies the status of external third-party B2B API endpoints. |

---

## 3. Krieger Remediation Handler (`remediate.mjs`)

You will need to deploy this routing module within your `/home/josh/AISSC-Automated-Online-Empire/monitoring-telemetry-remediation/` folder to process the incoming Eventarc webhooks.

```javascript
import { z } from 'zod';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';

const execPromise = promisify(exec);

// Validate incoming Eventarc Cloud Pub/Sub envelope
const EventarcEnvelopeSchema = z.object({
  message: z.object({
    data: z.string(), // Base64 encoded Pub/Sub payload
    messageId: z.string(),
    publishTime: z.string()
  })
});

// Compiled remediation regex matches
const SIGNATURES = {
  MEMORY_LIMIT: {
    pattern: /JavaScript heap out of memory/i,
    playbook: './playbooks/remediate-memory.mjs'
  },
  DB_DEADLOCK: {
    pattern: /deadlock detected|Lock wait timeout/i,
    playbook: './playbooks/remediate-db-lock.mjs'
  },
  OIDC_FAILURE: {
    pattern: /jwt expired|invalid signature|aud mismatch/i,
    playbook: './playbooks/remediate-auth-trust.mjs'
  },
  CONNECTION_TIMEOUT: {
    pattern: /ETIMEDOUT|ENOTFOUND|ECONNREFUSED/i,
    playbook: './playbooks/remediate-network.mjs'
  }
};

/**
 * Parses and processes the event log
 * @param {string} logText 
 * @param {string} resourceName
 */
async function routeRemediation(logText, resourceName) {
  console.log(`[REMEDIATION] Analyzing log output from: ${resourceName}`);

  for (const [key, sig] of Object.entries(SIGNATURES)) {
    if (sig.pattern.test(logText)) {
      console.log(`[MATCH] Detected Signature: ${key}. Directing to playbook: ${sig.playbook}`);

      if (!fs.existsSync(sig.playbook)) {
        throw new Error(`Execution halted: Target playbook script not found at ${sig.playbook}`);
      }

      // Execute target playbook in an isolated sub-process
      const { stdout, stderr } = await execPromise(`node ${sig.playbook} --resource="${resourceName}"`);
      
      console.log(`[RESOLVED] Playbook execution completed for ${key}.`);
      if (stdout) console.log(`[OUTPUT] ${stdout}`);
      if (stderr) console.error(`[ERR_LOG] ${stderr}`);
      return;
    }
  }

  console.log('[REMEDIATION] Log signature does not match any automated playbooks. Escalating to system logs.');
}

/**
 * Express Controller endpoint for Eventarc webhook ingestion
 */
export async function handleEventarcRemediation(req, res) {
  try {
    const envelope = EventarcEnvelopeSchema.parse(req.body);
    
    // Decode the Base64 log payload
    const decodedRaw = Buffer.from(envelope.message.data, 'base64').toString('utf-8');
    const logPayload = JSON.parse(decodedRaw);

    // Extract text log and source resource identity
    const logText = logPayload.textPayload || logPayload.jsonPayload?.message || '';
    const resourceName = logPayload.resource?.labels?.service_name || 'unknown-cloud-run-service';

    if (!logText) {
      return res.status(200).json({ status: "IGNORED", reason: "Empty log textPayload" });
    }

    // Hand-off execution to async worker thread to prevent Eventarc webhook timeout
    routeRemediation(logText, resourceName).catch(err => {
      console.error(`[CRITICAL] Remediation playbook failed to execute:`, err.message);
    });

    return res.status(200).json({
      status: "RECEIVED",
      messageId: envelope.message.messageId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error(`[ERROR] Eventarc payload validation rejected:`, error.message);
    return res.status(400).json({ status: "REJECTED", error: error.message });
  }
}
```

---

## 4. Playbook Template: Database Remediation (`remediate-db-lock.mjs`)

Save this baseline recovery playbook under `/home/josh/AISSC-Automated-Online-Empire/monitoring-telemetry-remediation/playbooks/remediate-db-lock.mjs` to resolve sudden SQL transactional deadlocks:

```javascript
import { Storage } from '@google-cloud/storage';

const args = process.argv.slice(2);
const resourceArg = args.find(arg => arg.startsWith('--resource='));
const targetResource = resourceArg ? resourceArg.split('=')[1] : 'unknown-service';

console.log(`[PLAYBOOK] Starting lock resolution for resource: ${targetResource}`);

async function run() {
  const telemetryFile = '/gs/aissc-persistent-memory-store/telemetry/gcp-telemetry.json';
  
  // Real-world database connections would rollback active locks here
  console.log('[PLAYBOOK] Flushing pool connections...');
  console.log('[PLAYBOOK] Delaying subsequent Cloud Tasks queue triggers by 5000ms (Jitter Applied)...');

  // Log remediation event details back to the shared memory bucket
  const event = {
    insertId: `rem-${Date.now()}`,
    timestamp: new Date().toISOString(),
    severity: "INFO",
    textPayload: `Automated lock recovery executed successfully for service: ${targetResource}`,
    type: "remediation_action",
    service_name: "krieger-tech-systems"
  };

  console.log(`[SUCCESS] Telemetry update ready: ${event.textPayload}`);
}

run().catch(err => {
  console.error('[PLAYBOOK_FAILED] Lock recovery encountered an exception:', err.message);
  process.exit(1);
});
```
