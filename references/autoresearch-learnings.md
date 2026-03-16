# Autoresearch Learnings — Revenue Skills Library
*2026-03-13 | 31 experiments | Baseline 62 → 72/100 (+16%)*

## What Happened
Ran pi-autoresearch with an LLM-as-judge (claude-haiku-4-5 via Shopify AI proxy) scoring 23 revenue skills against a gold-standard rubric extracted from payments-platform-atc and customer-account-triage.

## The 7 Rubric Dimensions (from rubric.md)
| Dimension | Max | Avg Score | % | Status |
|-----------|-----|-----------|---|--------|
| Problem Definition & Scope | 15 | 13.8 | 92% | 🟢 Strong |
| Tool & Data Source Spec | 10 | 9.2 | 92% | 🟢 Strong |
| Investigation Workflow | 20 | 17.1 | 86% | 🟢 Good |
| SQL & Data Queries | 15 | 11.9 | 79% | 🟡 Weakest |
| Output Format & Template | 15 | 13.7 | 92% | 🟢 Strong |
| Error Handling & Edge Cases | 10 | 8.9 | 89% | 🟢 Good |
| Anti-Gaming Quality Signals | 15 | 11.2 | 74% | 🟡 Second weakest |

## The 72→78 Recipe
Skills that scored 78 vs 72 had these specific differences:
- **SQL/Data**: +1.9 avg (biggest delta) — more complete queries with interpretation guidance
- **Workflow**: +0.9 — deeper conditional branching in decision trees
- **Error Handling**: +0.9 — 8+ specific scenarios vs generic "tell the user"
- **Quality Signals**: +0.8 — more domain vocabulary, negative instructions
- **Output Format**: +0.5 — conditional inclusion logic ("if closed-lost, add loss reason section")

**Concrete pattern**: Tools table with fallback column + 8+ named error scenarios + conditional output by scenario type + domain-specific vocabulary (not generic business terms) + explicit scope boundaries ("this skill does NOT do X")

## Tier Distribution
| Tier | Score | Skills | What Makes Them Different |
|------|-------|--------|--------------------------|
| Top | 78 | prospect-researcher, opp-compliance-checker, account-research, meeting-prep, account-context-sync, product-gap-tracker | Full tools tables, 8+ error scenarios, conditional output, UAL-first |
| Good | 72 | 15 skills | Have most structure but lack depth in SQL interpretation, conditional branching, or domain vocabulary |
| Stuck | 62 | competitive-positioning, sales-manager-dashboard | Structural mismatch — reference skill and build skill don't fit investigation workflow pattern |

## What the Judge Keeps Asking For (Top Gaps at 72)
These are the recurring `top_gap` values that prevent 72→78:
1. **Tool unavailability handling** — generic "tell user" instead of specific fallback chains
2. **SQL interpretation guidance** — queries exist but no "if this returns >X, it means Y"
3. **Conditional decision trees** — workflows are linear, not branching on input type
4. **Domain vocabulary depth** — uses generic terms instead of field-specific language
5. **Negative instructions** — missing "do NOT do X" guardrails

## Key Insights

### 1. The 72 Ceiling is Real
After 31 experiments, the composite stabilized at 72. The judge cycles between dimensions — fixing one exposes the next. Breaking through requires addressing multiple dimensions simultaneously.

### 2. Structural Skills Don't Fit the Rubric
`competitive-positioning` (a reference/playbook skill) and `sales-manager-dashboard` (a build/deploy guide) scored 62 because they're not "investigation workflows." The rubric was designed from triage/investigation skills. Need a separate rubric for reference skills and build skills.

### 3. SQL Interpretation > SQL Existence
Having SQL blocks gets you to 72. Having SQL blocks WITH interpretation guidance ("if count = 0, the account doesn't exist in SF; if count > 1, there are duplicates — take the most recent") gets you to 78. The delta isn't about having queries, it's about telling the agent what the results mean.

### 4. Error Handling Must Be Specific, Not Generic
"If BigQuery fails, tell the user" = 72. "If UAL returns no rows: check domain normalization (strip www, protocol). If UAL returns multiple matches: take most recent by updated_at. If sales_accounts_v1 is stale (>24h): fall back to base__salesforce_banff_accounts" = 78.

### 5. The Anti-Gaming Dimension Works
The judge correctly identifies domain vocabulary, negative instructions, and specific file references as quality signals. Skills that just added section headers without substance stayed at 72. Skills that added actual domain knowledge (MEDDPICC fields, SF stage names, coaching rubric details) reached 78.

## Methodology for Future Skills
When building a new skill, use this checklist to target 78+ from the start:

### Structure (gets you to 72)
- [ ] YAML frontmatter with 3+ trigger phrases in description
- [ ] Required Tools section (even if "no special tools needed")
- [ ] Numbered workflow steps (Step 0 = validation/ownership check)
- [ ] At least one SQL code block with FQ table names
- [ ] Output format section
- [ ] Error handling section (even if brief)

### Depth (gets you from 72→78)
- [ ] Tools TABLE with columns: Tool | Purpose | Fallback if Unavailable
- [ ] 8+ specific error scenarios with named recovery actions
- [ ] Conditional output format ("if scenario A → include X section, if scenario B → skip X")
- [ ] Decision tree in workflow ("Has account_id? → Yes → Step 2a / No → Step 2b")
- [ ] SQL interpretation guidance per query ("if returns 0 rows → means X, if >1 → means Y")
- [ ] 5+ domain-specific vocabulary terms (not generic business terms)
- [ ] 2+ negative instructions ("do NOT do X", "this skill is NOT for Y")
- [ ] Explicit scope boundaries (what it does AND doesn't do)

### Beyond 78 (manual, not automated)
- [ ] Reference external files (references/*.md) with specific content
- [ ] Self-learning mechanism (capture new patterns during execution)
- [ ] Multi-mode routing (batch vs single vs handoff)
- [ ] Cross-skill handoff logic ("when this skill finishes, suggest running X next")

## Files
- `autoresearch.jsonl` — 31 experiment records (append-only log)
- `autoresearch.md` — session document (objective, strategy, constraints)
- `autoresearch.sh` — LLM-judge grading script (bash + curl to AI proxy)
- `autoresearch-scores.json` — latest per-skill detailed scores
- `rubric.md` — 7-dimension scoring rubric
- `grade-skills.sh` — structural grading script (bash only, no LLM)
- `backups/skills-backup-20260313-1000/` — pre-autoresearch backup
