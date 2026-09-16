# AISSC-Automated-Online-Empire — Project Intake

> Fill this at assignment intake, BEFORE generating the other docs. Then run the generator.

## Intake Pattern
- [ ] **Fresh project** — new repo or empty dir: generate docs with `--scenario startup-mvp` (or matching scenario), mode by size.
- [ ] **Existing repo** — repo already present: inspect AGENTS.md/README, pick scenario by project type, generate with `--repo <path>`.
- [ ] **Blueprint-doc + unknown-state** — a design blueprint exists but the implementation state is unknown: locate the actual implementation first (search likely project dirs, check git remotes, read the blueprint doc's links), audit its state, THEN generate docs. Blueprint is referenced by path only — never copy its content.

## Project Facts
| Field | Value |
|-------|-------|
| **Project name** | AISSC-Automated-Online-Empire |
| **Repo path** | [Path to repo] |
| **Spec path** | [PATH TO SPEC] |
| **Blueprint path** | none |
| **Mode** | micro |
| **Scenario** | startup-mvp |
| **Date** | 2026-09-04T21:59:53.199Z |

## Discovery Notes
- [What exists already: repo state, docs found, agents installed]
- [What is missing]
- [Known constraints from AGENTS.md / README / blueprint]

## Next Steps
1. Run the generator: `node ~/.agents/skills/agency-nexus/scripts/generate-nexus-docs.mjs --project "AISSC-Automated-Online-Empire" --mode micro --scenario startup-mvp --repo [path] --spec [path]`
2. Review roster.json for unresolved slugs.
3. Fill remaining [BRACKET] spots in generated docs.