# Revenue Skills Library

**29 AI skills for Shopify sales teams**, mapped across the full merchant journey — from prospecting to expansion.

Built from how our highest performers work, aligned to the merchant journey, and grounded in leading practices and live data.

## Quick Start

Install any skill:
```bash
cp -r skills/<skill-name> ~/.pi/agent/skills/    # Pi
cp -r skills/<skill-name> ~/.claude/skills/       # Claude Code
```

## What's a Skill?

A skill is a reusable AI instruction set. When an AE needs to prep for a call, prioritize their pipeline, or write a follow-up, a skill does the research in parallel, pulls the right data from Salesforce and BigQuery, and delivers the output in 30 seconds instead of 30 minutes.

## Journey Coverage (29 skills)

| Stage | Skills | Count |
|-------|--------|:-----:|
| **Prospect** | prospect-researcher, signal-monitor, competitive-positioning, outbound-cadence, vertical-consumer-goods, techstack-fingerprint | 6 |
| **Envision** | meeting-prep, account-research, qualification-trainer, sales-call-coach | 4 |
| **Solution** | product-agentic, product-headless-hydrogen, agentic-plan-sell | 3 |
| **Demo** | sales-call-coach, acquisition-sales | 2 |
| **Deal Craft** | opp-compliance-checker, opp-hygiene, deal-prioritization, sf-writer | 4 |
| **Close** | deal-followup, sales-writer | 2 |
| **Launch** | account-context-sync | 1 |
| **Growth** | merchant-analytics-queries, daily-briefing | 2 |
| **Cross-cutting** | data-integrity-check, revenue-data-research, ae-se-collaboration, product-gap-tracker, summarize-last-call, sales-manager-dashboard | 6 |

## 4-Layer Architecture

```
Layer 0: Data Integrity    → data-integrity-check (runs before everything)
Layer 1: Data Access       → account-research, prospect-researcher, account-context-sync
Layer 2: Analysis          → opp-compliance, deal-prioritization, call-coach, qualification-trainer
Layer 3: Action            → sf-writer, deal-followup, sales-writer, meeting-prep, daily-briefing
Cross-cutting              → competitive-positioning, product-*, signal-monitor, outbound-cadence
```

## Quality System

Every skill is scored 0-100 by an LLM judge against a 7-dimension rubric:

1. Problem Definition & Scope (0-15)
2. Tool & Data Source Specification (0-10)
3. Investigation Workflow (0-20)
4. SQL & Data Queries (0-15)
5. Output Format (0-15)
6. Error Handling (0-10)
7. Anti-Gaming Quality Signals (0-15)

**Current average: 72/100** | 7 skills at 78 (top tier) | Target: 78+ for all

Run the grader: `bash autoresearch.sh <skill-name>` (~$0.05/skill via Shopify AI proxy)

## Contributing

1. Read `METHODOLOGY.md` for the full build process
2. Use `skill-creator` or `skill-architect` skills to draft a new skill
3. Score it: `bash autoresearch.sh <your-skill>` — target 70+
4. PR it to this repo

## Key Files

| File | What |
|------|------|
| `METHODOLOGY.md` | Full methodology: discovery, governance, skill anatomy, quality system |
| `rubric.md` | 7-dimension LLM judge scoring rubric |
| `autoresearch.sh` | LLM-as-judge grading script |
| `grade-skills.sh` | Free structural checklist (no LLM) |
| `PARKING-LOT.md` | Skill ideas and roadmap |
| `references/` | Reusable SQL queries, data source docs, signal scoring models |
| `skills/` | All 29 skill SKILL.md files |
