# Revenue Skills Library — Methodology & Approach

*Living document. Updated as patterns evolve.*
*Last updated: 2026-03-13*

---

## Discovery Method: How We Find Skill Opportunities

### Phase 1: Ecosystem Scan (Quick Directory)

**Goal:** Find what Shopify sellers have already built for themselves. Real tools with real users beat theoretical skill ideas every time.

**Approach:**
1. **Quick MCP global search** — query `search_global` with revenue/sales keywords across all 2,508+ indexed Quick sites
2. **Quick MCP site file browsing** — `list_site_files` to check last-modified dates (directory DB is stale since Sept 2025, file dates are ground truth for recency)
3. **Quick MCP content reading** — `get_site_file` to read index.html, README.md, AGENTS.md of interesting sites, strip HTML to extract purpose
4. **Slack search** — `quick.shopify.io` + revenue keywords in `#quick`, `#proj-revenue-tools-*`, `#amer-revenue-all` for newly shared sites
5. **BQ query extraction** — parse `<script>` blocks for SQL queries, extract table references and matching logic as reusable data patterns

**Key search terms that worked:**
- Sales pipeline forecast attainment, deal coaching enablement AE, merchant account research prospect intelligence
- sales enablement playbook competitive battle card, SE solution engineer demo discovery, revenue operations attainment quota forecast

**Productivity hack:** Background `quick mcp <site>` calls with 12-15s timeouts — most sites respond in 8-10s, some need the full 15s for first load.

### Phase 2: Prioritization

**Scoring criteria for Quick site → skill conversion:**

| Factor | Weight | What It Means |
|--------|:------:|---------------|
| Active usage (file dates < 30 days) | High | Someone is maintaining this — real need |
| Solves a problem we don't have a skill for | High | New capability gap filled |
| Has extractable data patterns (BQ queries) | High | Reusable SQL = instant enrichment |
| Multiple similar sites by different people | Medium | Convergent need — not just one person's pet project |
| Enriches an existing skill | Medium | Incremental value, lower risk |
| Requires backend infra (APIs, servers) | Low | Can't easily port to a Pi/Claude skill |

### Phase 3: Data Source Mining

**The real gold is in the SQL, not the UI.** When we find a useful Quick site:

1. Read the raw HTML with `get_site_file`
2. Search for BQ table references: `re.findall(r'([\w-]+\.[\w_-]+\.[\w_-]+)', text)` filtered for `shopify`/`sdp`/`rev_ops`
3. Extract SQL queries — look for `SELECT...FROM` patterns, `quick.dw.querySync` calls, CTE chains starting with `WITH`
4. Document the data source in `references/` with table, fields, matching logic, and which skills it powers
5. Build a reusable query pattern that any skill can call

**Example:** company-lookup.quick.shopify.io → extracted full UAL CTE query → saved to `references/company-lookup-ual-query.md` → integrated into 7 skills.

---

## Data Source Evaluation Framework

*Added 2026-03-12 after nearly adopting `sales.*` tables as replacements for `base__*` without verifying they were the same underlying data.*

### The Problem

As we discover more Quick sites, Slack tools, and internal dashboards, we'll encounter many BQ tables that look useful. Some are gold. Some are stale copies. Some are subtly wrong. Without a gate, we risk:
- **Silent data drift** — mart built in 2024, never updated, silently wrong
- **Duplicate data** — enriched mart that's 99% identical to our canonical source
- **Missing records** — mart that filters out soft-deleted or edge-case records
- **Wrong grain** — table aggregated at account level when we need opp level
- **Abandoned tables** — no owner, no pipeline, no freshness guarantee

### Two Practical Rules

**Rule 1: Recency wins (for all context).** When we get conflicting information from multiple sources — Slack threads, docs, Quick sites, Vault pages — check the dates. Most recent timestamp gets priority. Always surface the date so we can judge staleness.

**Rule 2: Test with a known entity (for all data).** Don't evaluate tables in the abstract. Pick a REAL account, opp, or deal we've already verified (e.g., a Diana org deal, or Venkat's own territory) and run the new table against it. If the output matches reality, it's trustworthy. If it doesn't, it's not.

### Evaluation Steps (in order — stop early if something fails)

**Step 1: Check the dates.** Every table has timestamps. Run this first:
```sql
SELECT MAX(updated_at) AS latest_update, MIN(created_at) AS oldest_record,
  COUNT(*) AS total_rows
FROM `candidate.table`
```
Compare against our known table. If the candidate is older or has fewer rows, it's already suspect.

**Step 2: Test with a known entity.** Pick a specific account/opp we trust (Diana's org works — we've verified those numbers against SF directly):
```sql
-- Pull from BOTH tables, compare side by side
SELECT 'known' AS src, name, stage_name, close_date, amount
FROM `our.canonical.table` WHERE opportunity_id = @known_opp_id
UNION ALL
SELECT 'candidate' AS src, name, current_stage_name, close_date, amount_usd
FROM `candidate.table` WHERE opportunity_id = @known_opp_id
```
If the core fields match, the data is trustworthy. If they don't — stop and investigate.

**Step 3: What's new here?** Column diff to see what the candidate adds:
```sql
SELECT n.column_name FROM `candidate.INFORMATION_SCHEMA.COLUMNS` n
LEFT JOIN `known.INFORMATION_SCHEMA.COLUMNS` k ON n.column_name = k.column_name
WHERE n.table_name = 'candidate_table' AND k.table_name = 'known_table' AND k.column_name IS NULL
```

**Step 4: What's missing?** Orphan check — does the candidate drop records?
```sql
SELECT 'in_ours_not_candidate' AS dir, COUNT(*) FROM `our.table` o
LEFT JOIN `candidate.table` c ON o.id = c.id WHERE c.id IS NULL
```
If our table has records the candidate doesn't, document WHY (soft deletes? date filter? record type filter?).

### Decision: adopt, enrich, or skip

| What you find | Action |
|---|---|
| Same data + extra columns + dates match | **Enrich** — use candidate for the extra columns only. Keep ours as canonical. |
| Same data + fewer records | **Skip** — ours is more complete. Note what's filtered out. |
| Different data entirely | **Adopt as new layer** — it's genuinely new information. |
| Data conflicts on overlapping fields | **Stop** — ask in #help-data-platform before proceeding. |
| Table hasn't been updated in >30 days | **Flag** — may be abandoned. Use patterns only, don't depend on it. |

### For non-data context (Slack, docs, Vault pages, Quick sites)

Same principle: **check the date, most recent wins.** When we find conflicting information:
1. Note both sources with their dates
2. Most recent gets priority as the "current truth"
3. If the older source has detail the newer one doesn't, merge — take structure from recent, fill gaps from older
4. Always surface the date in our reference docs so future sessions can judge

---

## Skill Design Method: How We Build

### Anatomy of a Revenue Skill

Every revenue skill follows this structure:

```
---
name: skill-name
description: [What it does, when to trigger — include natural language trigger phrases]
---

# Skill Name
[One-line purpose]

## Required Tools
[What MCP servers / CLI tools are needed]

## Workflow
### Step 0: [Data validation / ownership check — always first]
### Step 1-N: [Core workflow steps]

## Output Template
[Exact format the skill produces — copy-paste ready for the user]

## Error Handling
[What to do when data sources fail]

## Anti-Patterns
[Common mistakes to avoid]
```

### Design Principles

1. **UAL-first for anything account-related** — Check the Unified Account List before doing anything. This prevents stepping on existing accounts, validates territory, and resolves ownership. The UAL query is a foundational primitive (see `references/company-lookup-ual-query.md`).

2. **Data → Insight → Recommendation** — Raw data is table 1, insight is "what does this mean," recommendation is "what should you do." Most existing tools stop at data. Our skills go to recommendation.

3. **Dual-install always** — Skills go to BOTH `~/.pi/agent-shopify/skills/` AND `~/.claude/skills/`. Pi and Claude Code must have the same capabilities. Use `cp` after every skill write.

4. **BQ queries are reusable primitives** — When a skill needs a query, check if another skill already has it. If so, reference, don't duplicate. Common queries go in `references/`.

5. **Trigger phrase engineering** — The `description` field is how the skill gets auto-discovered. Include:
   - Explicit commands: "research [company]", "prospect intel"
   - Natural language: "who is this account", "is this taken"
   - Context triggers: "when meeting-prep finds no internal data"

6. **Progressive data gathering** — Start with cheapest/fastest data source, only escalate if needed:
   - UAL (< 1s) → Salesforce (2-3s) → BigQuery analytics (5-10s) → Web search (10-15s)

### Integration with Merchant Journey Framework

Each skill maps to a stage in the merchant journey (as documented on the Quick site):

| Journey Stage | Skills |
|---|---|
| Awareness & Consideration | prospect-researcher, competitive-positioning, vertical-battle-cards |
| Evaluate & Decide | meeting-prep, qualification-trainer, account-research |
| Purchase & Commit | opp-compliance-checker, opp-hygiene |
| Implementation & Onboarding | deal-followup, account-context-sync |
| Growth & Optimization | merchant-growth-advisor, signal-monitor |
| At Risk & Recovery | churn-intelligence |
| Cross-cutting (all stages) | sales-call-coach, daily-briefing, sales-writer |

---

## Data Source Registry

### Core Revenue Tables

**Layer 1: Ownership (UAL)**
| Table | What | Skills Using It |
|---|---|---|
| `sdp-prd-commercial.mart.unified_account_list` | Master account dedup (UAL) | prospect-researcher, opp-hygiene, account-research, meeting-prep, deal-followup, opp-compliance-checker, qualification-trainer |
| `shopify-dw.raw_salesforce_banff.account` | SF accounts | prospect-researcher, opp-compliance-checker |
| `shopify-dw.raw_salesforce_banff.website__c` | SF websites → account mapping | prospect-researcher, account-research |
| `shopify-dw.raw_salesforce_banff.user` | SF users (owner lookup) | prospect-researcher, opp-compliance-checker |

**Layer 2: Enriched Context (sales.* marts — built on top of base, validated 2026-03-12)**
*Same SF source data as base, with 34+ extra enriched columns. Use for enrichments only, NOT as canonical source.*
| Table | Extra vs Base | Skills Using It |
|---|---|---|
| `shopify-dw.sales.sales_accounts_v1` | `account_priority_{d2c,retail,b2b}`, `domain_clean`, `account_owner`, `territory_{region,segment,subregion}`, `primary_shop_id`, `primary_contact_email`, `merchant_success_manager`, `ecomm_platform` enriched | prospect-researcher, account-research, meeting-prep, deal-prioritization, competitive-positioning |
| `shopify-dw.sales.sales_opportunities` | `compelling_event`, `market_segment`, `team_segment`, `territory_name`, `salesforce_owner_name`, `forecast_category`, `description`, `next_step` | opp-compliance-checker, opp-hygiene, deal-prioritization, meeting-prep |

**Layer 3: Signals (new tables — NOT in base)**
| Table | What | Skills Using It |
|---|---|---|
| `shopify-dw.sales.shop_to_sales_account_mapping` | Shop ID → SF Account ID bridge (THE missing link) | signal-monitor, account-research, prospect-researcher, meeting-prep, merchant-health-report |
| `shopify-dw.accounts_and_administration.shop_subscription_milestones` | Trial events (free/paid trial, first subscription) | signal-monitor, prospect-researcher, meeting-prep, daily-briefing |
| `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` | Campaign/event/webinar engagement | signal-monitor, meeting-prep, account-context-sync, deal-followup |

**Layer 3: Revenue Operations**
| Table | What | Skills Using It |
|---|---|---|
| `shopify-dw.base.base__salesforce_banff_opportunities` | Opportunities (diana-dashboard source) | diana-dashboard, opp-hygiene, deal-prioritization |
| `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events` | Quota/attainment | diana-dashboard, sales-manager-dashboard |
| `sdp-for-analysts-platform.rev_ops_prod.temp_sales_performance` | Full funnel metrics | rev-funnel-ops, emea-sales-dashboard |
| `shopify-dw.base.base__salesloft_conversations_extensive` | Call transcripts | sales-call-coach, meeting-prep, diana-dashboard (Loss Intelligence) |
| `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity` | Activity signals | diana-dashboard (engagement tiers) |
| `sdp-for-analysts-platform.rev_ops_prod.report_revenue_reporting_sprint_billed_revenue_cohort` | PBR at opp grain | diana-dashboard |

### Reference Documents

| File | What | Updated |
|---|---|---|
| `references/company-lookup-ual-query.md` | Full UAL + SF website fuzzy matching SQL with field reference | 2026-03-12 |
| `references/smokesignals-signal-scoring.md` | 17-signal tiered scoring, 5 BQ tables, AI outreach schema, EDGAR integration | 2026-03-12 |
| `references/smokesignals-skill-impact-analysis.md` | Deep cross-reference: every table/pattern mapped to every skill with impact scores | 2026-03-12 |
| `PARKING-LOT.md` | 22+ items: skill ideas, enrichments, reference sites | 2026-03-12 |
| `QUICK-DIRECTORY-SCAN-V2.md` | Quick MCP scan results with 12 high-signal sites | 2026-03-12 |
| `QUICK-DIRECTORY-SCAN.md` | Original v1 directory scan (Sept 2025 data, older) | 2026-03-12 |
| `references/autoresearch-learnings.md` | Full autoresearch analysis: 31 experiments, tier system, 72→78 recipe, dimension scores | 2026-03-13 |
| `rubric.md` | 7-dimension LLM-judge scoring rubric (gold-standard patterns) | 2026-03-13 |
| `autoresearch.sh` | LLM-judge grading script (claude-haiku via Shopify AI proxy) | 2026-03-13 |
| `grade-skills.sh` | Structural grading script (bash, no LLM, free) | 2026-03-13 |

---

## Quality Method: How We Measure and Improve

*Added 2026-03-13 after running pi-autoresearch on the full skills library (31 experiments, baseline 62 → 72/100).*

### The Problem We Solved

Skills are markdown instructions for AI agents. How do you know if they're any good? You can't `wc -c` quality. Running grep for section headers catches structure but not substance — an agent gaming a checklist will add boilerplate `## Error Handling\nIf it fails, try again` and score perfectly while making the skill worse.

### Our Approach: LLM-as-Judge with Gold-Standard Rubric

1. **Extract patterns from the best skills in Shopify's catalog** (payments-platform-atc, customer-account-triage — written by senior engineers for critical production workflows)
2. **Encode those patterns into a 7-dimension rubric** (`rubric.md`) that measures content quality, not just structure
3. **Use an LLM (claude-haiku-4-5) to score each skill** against the rubric — cheap (~$0.05/skill), fast (~10s/skill), and harder to game than regex
4. **Run pi-autoresearch** to loop: pick lowest skill → fix top gap → re-grade → keep if improved

### The 7 Dimensions

| # | Dimension | Max | What Good Looks Like |
|---|-----------|-----|---------------------|
| 1 | Problem Definition & Scope | 15 | Clear purpose + explicit boundaries + modes (batch vs single) |
| 2 | Tool & Data Source Spec | 10 | Tools TABLE with fallback column, not just a list |
| 3 | Investigation Workflow | 20 | Decision trees with conditional branching, not linear steps |
| 4 | SQL & Data Queries | 15 | Complete runnable SQL + interpretation guidance per query |
| 5 | Output Format & Template | 15 | Required vs optional sections + conditional inclusion logic |
| 6 | Error Handling & Edge Cases | 10 | 8+ specific named scenarios with recovery actions |
| 7 | Anti-Gaming Quality Signals | 15 | Domain vocabulary, negative instructions, specific references |

### Tier System (from autoresearch results)

| Tier | Score | What It Takes |
|------|-------|---------------|
| 🔴 Stub | <50 | Missing most structure — needs full rewrite |
| 🟡 Functional | 50-69 | Has basic structure but gaps in depth |
| 🟢 Good | 70-77 | Solid structure, needs deeper SQL interpretation + error handling |
| ⭐ Excellent | 78+ | Tools table + 8+ error scenarios + conditional output + domain vocab |

### The 72→78 Recipe (hard-won from 31 experiments)

Getting from 72→78 requires addressing multiple dimensions simultaneously. The specific additions that work:

1. **Tools TABLE** (not list) with columns: Tool | Purpose | Fallback if Unavailable
2. **8+ specific error scenarios** with named recovery actions (not "if it fails, tell the user")
3. **Conditional output format** ("if closed-lost → add loss reason section; if open → skip")
4. **Decision tree** in workflow ("Has account_id? → Yes → Step 2a / No → Step 2b")
5. **SQL interpretation guidance** per query ("if returns 0 rows → account not in SF; if >1 → duplicates, take most recent")
6. **5+ domain vocabulary terms** (MEDDPICC, UAL, PBR, BDR — not generic "pipeline" or "deal")
7. **2+ negative instructions** ("do NOT skip UAL check", "this skill is NOT for existing account enrichment")
8. **Explicit scope boundaries** (what it does AND doesn't do)

### Key Insight: Goodhart's Law Protection

The LLM judge evaluates *content quality*, not *section headers*. A skill that adds `## Error Handling\nIf it fails, try again.` gets 3/10. A skill that adds 8 specific scenarios with recovery chains gets 9/10. This prevents gaming — the only way to improve the score is to genuinely improve the skill.

### Grading Tools

| Tool | What | Cost | When to Use |
|------|------|------|-------------|
| `bash autoresearch.sh` | LLM judge (full rubric) | ~$0.05/skill | After major edits, before shipping |
| `bash autoresearch.sh <name>` | LLM judge (single skill) | ~$0.05 | Quick check during development |
| `bash grade-skills.sh` | Structural checklist | Free | Fast smoke test, regression detection |
| pi-autoresearch loop | Automated improvement | ~$1-3/full run | Batch quality improvement sprints |

### Weakest Dimensions (where to focus manual effort)

1. **SQL interpretation** (79%) — most skills have queries but don't explain what results mean
2. **Quality signals** (74%) — need more domain vocabulary and negative instructions
3. **Tool unavailability** — most skills say "tell user" instead of specific fallback chains

---

## Process: Adding a New Skill

1. **Check parking lot** — is it already tracked? Update status if so
2. **Check existing skills** — does something similar exist? Enrich rather than duplicate
3. **Mine the Quick site** (if sourced from one) — extract SQL, document data sources
4. **Write the SKILL.md** — follow anatomy template above, UAL-first for account skills. **Target 78+ from the start** using the 72→78 recipe checklist above
5. **Grade the skill** — run `bash autoresearch.sh <skill_name>` to check quality score. Fix top_gap before shipping
6. **Install to both locations** — `~/.pi/agent/skills/` AND `~/.claude/skills/`
7. **Update PARKING-LOT.md** — mark item as done, note what was built
8. **Update memory** — `dailyContext.md` (completed section) + `activeProjects.md` if project status changed
9. **Test the skill** — ask a natural language question that should trigger it, verify it activates and produces correct output

---

## Architecture: 4-Layer Skill Stack

Revenue skills operate in a layered architecture. Each layer depends on the one below it.

### Layer 0 — Data Integrity (pre-flight)
**Skill:** `data-integrity-check`
**Purpose:** Validate that Salesforce/UAL data is clean BEFORE any analysis skill runs.
**Checks:** Account duplicates, UAL field completeness (82 fields), territory owner activity, worker sales attributes, contact duplicates.
**Data sources:** `sdp-prd-commercial.mart.unified_account_list`, `shopify-dw.raw_salesforce_banff.account`, 20 UAL null-check scratch tables, 16 territory inspector tables, worker attributes table.
**Returns:** Confidence envelope (HIGH/MEDIUM/LOW) + specific warnings + data quality score.
**Origin:** Molly Parapini's 5 RevOps data quality Quick sites (March 2026).

### Layer 1 — Data Access (UAL + enrichment)
**Skills:** `account-research`, `prospect-researcher`, `account-context-sync`
**Purpose:** Retrieve and enrich account/merchant data from UAL, Salesforce, Slack, Drive, BigQuery.
**Data sources:** UAL, SF opps/accounts/contacts, Salesloft transcripts, Google Drive, Slack threads.
**Speed:** UAL lookup <1s, enriched context 1-2s, full signals 3-10s.

### Layer 2 — Analysis & Scoring
**Skills:** `opp-compliance-checker`, `opp-hygiene`, `deal-prioritization`, `sales-call-coach`, `qualification-trainer`
**Purpose:** Score, evaluate, and diagnose deals, opps, and rep performance.
**Depends on:** Layer 0 (confidence envelope) + Layer 1 (data).

### Layer 3 — Action & Output
**Skills:** `sf-writer`, `deal-followup`, `sales-writer`, `meeting-prep`, `daily-briefing`
**Purpose:** Generate artifacts — emails, Salesforce updates, prep cards, briefings.
**Depends on:** Layer 2 (analysis) or Layer 1 (data) + Layer 0 (integrity).

### Cross-Cutting
**Skills:** `competitive-positioning`, `product-agentic`, `product-headless-hydrogen`, `agentic-plan-sell`, `vertical-consumer-goods`, `techstack-fingerprint`, `shopify-expert`
**Purpose:** Domain knowledge advisors that enrich any layer with platform/competitive context.

### Integration Pattern
Every Layer 1-3 skill that touches SF/UAL data should include:
```
Step 0: Run data-integrity-check for this account/opp/rep.
        If confidence LOW → prepend ⚠️ warnings to output.
        If confidence MEDIUM → note warnings but proceed.
        If confidence HIGH → proceed normally.
```

### Connectors: Quick Site → Skill Pipeline
Revenue Quick sites across Shopify are potential skill sources or data quality feeds:

| Quick Site | What It Provides | Connected Skill |
|-----------|-----------------|-----------------|
| salesforceaccountdupecheck.quick | Account dupe detection | data-integrity-check |
| salesforcecontactdupecheck.quick | Contact dupe detection | data-integrity-check |
| territoryinspector.quick | Territory health checks | data-integrity-check |
| ualinspector.quick | 82 UAL data quality checks | data-integrity-check |
| workersalesattributecheck.quick | Worker attribute gaps | data-integrity-check |
| salesforcedatadictionary.quick | SF field definitions | All skills (reference) |
| smokesignals.quick | 17-signal merchant scoring | signal-monitor (planned) |
| siteaudit.quick | Storefront CWV/Lighthouse | merchant-health-report (planned) |
| sales-skill-lib.quick | Merchant journey + skills map | (meta — our own site) |
| revenue-skills-quiz.quick | Knowledge verification quiz | (meta — verification) |

### Why This Architecture Matters
Without Layer 0, every skill blindly trusts its input data. A deal-prioritization skill that scores an opportunity HIGH because the fit scores look good — but doesn't know the fit scores are null and defaulting to zero — is worse than useless. It's actively misleading. Layer 0 prevents this by giving every downstream skill a confidence envelope that says "trust this data" or "proceed with caution."
