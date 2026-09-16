# kanban-dashboard

Static, Linear-style Kanban board showing the AISSC agent fleet's live work
state. It is Sheryl's control-plane view of fleet activity: questions awaiting
her, pending operational actions, in-flight assignments, and completed work.

## Run

No build step required (vanilla HTML/CSS/JS, no dependencies). Serve over HTTP:

```bash
cd components/kanban-dashboard
python3 -m http.server 8000
# open http://localhost:8000
```

Opening `index.html` directly via `file://` will not work because browsers
block `fetch()` on local files; the page shows a toast explaining this.

## Interchange Contract

`data/jobs.json` is the interchange contract. Fleet agents (Sheryl, Krieger,
Pam, Malory, Barry) update this file with their task states; the board renders
whatever is there. Job shape:

```json
{
  "id": "KAN-01",
  "title": "Short task title",
  "state": "todo | in_progress | done",
  "assignee": "Sheryl | Krieger | Barry | Malory | Pam",
  "due": "YYYY-MM-DD",
  "labels": ["optional", "chips"]
}
```

Columns map directly to `state` values (`question` maps to "Questions for
Sheryl"; `todo` to "Pending Actions"; `in_progress`; `done`).

## Files

- `index.html` - board markup + render logic
- `styles.css` - Linear-style dark theme
- `data/jobs.json` - current fleet task state (agent-updated)
- `README.md` - this file

## Deployment

Static hosting on GCS is wired in the CI/CD workflow (`deploy-apps` job,
`kanban-dashboard` matrix component), which syncs this directory to a public
bucket.