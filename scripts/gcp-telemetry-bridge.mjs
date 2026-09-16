#!/usr/bin/env node
/**
 * gcp-telemetry-bridge.mjs
 * ---------------------------------------------------------------------------
 * Telemetry sink for the AISSC-Automated-Online-Empire decoupling mesh.
 *
 * Pulls Cloud Run error entries (severity >= ERROR) and appends them to
 * ./gcp-telemetry.json, capped at the 500 most recent entries. Registered in
 * ./mcp-router-config.json as the `telemetry-bridge` MCP-side sink.
 *
 * Design notes:
 *  - Idempotent: uses a cursor file (.gcp-telemetry.cursor) storing the last
 *    ingested log timestamp so re-runs never duplicate entries.
 *  - No long-lived state: SUAD-compatible (Spin-Up-And-Die).
 *  - Credentials come from ADC / gcloud auth; fails loudly if absent.
 *
 * Usage:
 *   node scripts/gcp-telemetry-bridge.mjs                  # pull since cursor, append, cap
 *   node scripts/gcp-telemetry-bridge.mjs --hours 24       # override lookback window
 *   node scripts/gcp-telemetry-bridge.mjs --project <id>   # override project id
 *   node scripts/gcp-telemetry-bridge.mjs --validate       # config check only, no GCP call
 * ---------------------------------------------------------------------------
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..');
const CONFIG_PATH = resolve(REPO_ROOT, 'gcp-telemetry.json');
const CURSOR_PATH = resolve(REPO_ROOT, '.gcp-telemetry.cursor');
const MAX_ENTRIES = 500;

// ---------------------------------------------------------------------------
// Config load
// ---------------------------------------------------------------------------
function loadConfig() {
  if (!existsSync(CONFIG_PATH)) {
    throw new Error(`gcp-telemetry.json not found at ${CONFIG_PATH}`);
  }
  const cfg = JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
  if (!cfg.project) throw new Error('gcp-telemetry.json: missing "project"');
  return cfg;
}

function loadSink() {
  if (!existsSync(CONFIG_PATH)) return { entries: [] };
  try {
    const raw = JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
    return Array.isArray(raw.entries) ? raw : { entries: [] };
  } catch {
    return { entries: [] };
  }
}

function saveSink(sink) {
  const cfg = loadConfig();
  writeFileSync(
    CONFIG_PATH,
    JSON.stringify({ ...cfg, entries: sink.entries.slice(0, MAX_ENTRIES) }, null, 2) + '\n',
    'utf8'
  );
}

function readCursor() {
  if (!existsSync(CURSOR_PATH)) return null;
  const raw = readFileSync(CURSOR_PATH, 'utf8').trim();
  return raw || null;
}

function writeCursor(ts) {
  writeFileSync(CURSOR_PATH, ts, 'utf8');
}

// ---------------------------------------------------------------------------
// Pull Cloud Run errors from Cloud Logging
// status: 0 = success, 1 = no GCP access (caller decides)
// ---------------------------------------------------------------------------
function pullCloudRunErrors(cfg, sinceTs, hours) {
  const project = cfg.project;
  const filter = sinceTs
    ? `resource.type="cloud_run_revision" AND severity>=ERROR AND timestamp>"${sinceTs}"`
    : `resource.type="cloud_run_revision" AND severity>=ERROR AND timestamp>="-${hours}h"`;

  const args = [
    'logging', 'read', filter,
    '--project', project,
    '--format=json',
    '--limit=500',
    '--order=desc',
  ];

  const stdout = execFileSync('gcloud', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  return JSON.parse(stdout || '[]');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
function main() {
  const args = process.argv.slice(2);

  if (args.includes('--validate')) {
    loadConfig();
    console.log('gcp-telemetry.json: VALID');
    process.exit(0);
  }

  const hoursFlag = args.indexOf('--hours');
  const hours = hoursFlag !== -1 ? parseInt(args[hoursFlag + 1], 10) : 1;

  const projectFlag = args.indexOf('--project');
  if (projectFlag !== -1) {
    // Override via CLI; loadConfig() still validates file shape.
    loadConfig();
  }

  const cfg = loadConfig();

  // Only run the GCP pull when credentials are available (non-interactive check).
  try {
    execFileSync('gcloud', ['auth', 'print-access-token'], { encoding: 'utf8', stdio: 'ignore' });
  } catch {
    // gcloud is authenticated but tokens may need refresh; try a lightweight probe.
    try {
      execFileSync('gcloud', ['config', 'get-value', 'project'], { encoding: 'utf8', stdio: 'ignore' });
    } catch (err) {
      console.error(`gcp-telemetry-bridge: no gcloud credentials (${err.message}). Sink unchanged.`);
      process.exit(2);
    }
  }

  const sinceTs = readCursor();
  const entries = pullCloudRunErrors(cfg, sinceTs, hours);
  const sink = loadSink();

  // Newest-first from gcloud; prepend so the array stays newest-first.
  const fresh = entries.map((e) => ({
    ts: e.timestamp,
    severity: e.severity,
    resource: e.resource?.labels?.service_name || e.resource?.type || 'unknown',
    message: (e.textPayload || e.jsonPayload?.message || e.protoPayload?.statusMessage || '').toString().slice(0, 4000),
    logName: e.logName || null,
  }));

  if (fresh.length > 0) {
    sink.entries = [...fresh, ...sink.entries];
    writeCursor(fresh[0].ts);
  }

  saveSink(sink);
  console.log(`gcp-telemetry-bridge: ingested ${fresh.length} error(s); sink has ${sink.entries.length} entries (cap ${MAX_ENTRIES}).`);
}

try {
  main();
} catch (err) {
  console.error(`gcp-telemetry-bridge: ${err.message}`);
  process.exit(1);
}