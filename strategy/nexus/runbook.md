# AISSC-Automated-Online-Empire — NEXUS Runbook

## Metadata
| Field | Value |
|-------|-------|
| **Project** | AISSC-Automated-Online-Empire |
| **Mode** | micro |
| **Scenario** | startup-mvp |
| **Duration** | 4-6 weeks |
| **Spec** | [PATH TO SPEC] |
| **Blueprint reference** | none |
| **Generated** | 2026-09-04T21:59:53.199Z |

## Overview
[One paragraph: what this project is and what this runbook governs. Fill from the spec.]

## Mode Rationale
[Why micro was chosen: task size, timeline, team size. See QUICKSTART mode table.]

## Team Roster
### Core Team (activation: always)
| Agent | Slug | Installed |
|-------|------|-----------|
| Agents Orchestrator | `agents-orchestrator` | ✅ installed |
| Senior Project Manager | `project-manager-senior` | ✅ installed |
| Sprint Prioritizer | `product-sprint-prioritizer` | ✅ installed |
| UX Architect | `design-ux-architect` | ✅ installed |
| Frontend Developer | `engineering-frontend-developer` | ✅ installed |
| Backend Architect | `engineering-backend-architect` | ✅ installed |
| DevOps Automator | `engineering-devops-automator` | ✅ installed |
| Evidence Collector | `testing-evidence-collector` | ✅ installed |
| Reality Checker | `testing-reality-checker` | ✅ installed |

### Growth Team (activation: week 3+)
| Agent | Slug | Installed |
|-------|------|-----------|
| Growth Hacker | `marketing-growth-hacker` | ✅ installed |
| Content Creator | `marketing-content-creator` | ✅ installed |
| Social Media Strategist | `marketing-social-media-strategist` | ✅ installed |

### Support Team (activation: as needed)
| Agent | Slug | Installed |
|-------|------|-----------|
| Brand Guardian | `design-brand-guardian` | ✅ installed |
| Analytics Reporter | `support-analytics-reporter` | ✅ installed |
| Rapid Prototyper | `engineering-rapid-prototyper` | ✅ installed |
| AI Engineer | `engineering-ai-engineer` | ✅ installed |
| Performance Benchmarker | `testing-performance-benchmarker` | ✅ installed |
| Infrastructure Maintainer | `support-infrastructure-maintainer` | ✅ installed |

## Pipeline Phases
| Phase | Name | Gate Keeper | Status |
|-------|------|-------------|--------|
| 0 | Discovery | Executive Summary Generator | Pending |
| 1 | Strategy | Studio Producer + Reality Checker | Pending |
| 2 | Foundation | DevOps Automator + Evidence Collector | Pending |
| 3 | Build | Agents Orchestrator | Pending |
| 4 | Hardening | Reality Checker (sole authority) | Pending |
| 5 | Launch | Studio Producer + Analytics Reporter | Pending |
| 6 | Operate | Studio Producer (governance) | Pending |

## Quality Gates
- A quality gate runs at every phase boundary; the gate keeper records PASS/FAIL with evidence.
- Dev↔QA loop: assign → implement → QA verdict → retry (max 3) → escalate.
- Evidence required for all assessments. Reality Checker defaults to NEEDS WORK.
- Phase 4 (Hardening) is THE FINAL GATE — Reality Checker is sole authority.

## Handoff Protocol
- Every agent-to-agent transfer uses the Standard Handoff template (handoffs/handoff.md).
- QA verdicts use handoffs/qa-pass.md or handoffs/qa-fail.md.
- Escalations (3 failed attempts) use handoffs/escalation.md.

## Status Reporting
- Update status-report.md at every phase gate and task completion.
- Current phase: 0 - Discovery

## Task List
- Live task list: /home/josh/AISSC-Automated-Online-Empire/strategy/nexus/task-list.md