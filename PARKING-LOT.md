# Skills Library Parking Lot
*Created: 2026-03-12 | Source: Quick Directory deep-dive (2,508 sites scanned)*

Items to tackle one-by-one. Each needs: research the existing tool → decide build/adapt/skip → implement if go.

---

## 🆕 New Skill Ideas (from ecosystem scan)

### 1. `prospect-researcher` ⭐ HIGH — ✅ BUILT (2026-03-12)
- **Source**: call-prep.quick.shopify.io + company-lookup.quick.shopify.io (UAL)
- **What**: UAL ownership check FIRST → external web research → Shopify fit assessment → discovery questions → compiled brief
- **Installed**: ~/.pi/agent-shopify/skills/ + ~/.claude/skills/ (158 lines)
- **Key feature**: UAL pre-check prevents stepping on existing accounts; decision tree (owned → STOP, unowned → proceed)

### 2. `signal-monitor` ⭐ HIGH
- **Source**: smokesignals.quick.shopify.io (Jackson Waggoner, AE)
- **What**: Monitor BoB for news, SEC filings, financial reports, personnel changes, store openings → score as outreach triggers
- **Pattern**: Vite/React app with Quick APIs (bundle too large to inspect, 267KB)
- **Stage**: Awareness & Consideration
- **Action**: Reach out to Jackson Waggoner or reverse-engineer the approach; EMEA interest noted (need non-US equivalents for SEC)

### 3. `opp-compliance-checker` ⭐ HIGH — ✅ BUILT (2026-03-12)
- **Source**: oppcheckr.quick.shopify.io + company-lookup.quick.shopify.io (UAL)
- **What**: UAL territory validation → opp creation standards → data completeness → activity validation → compliance report
- **Installed**: ~/.pi/agent-shopify/skills/ + ~/.claude/skills/ (173 lines)
- **Key feature**: 5-step validation with MEDDPICC-aligned checks; severity levels (🔴 non-compliant / 🟡 needs review / ✅ compliant)

### 4. `pitch-builder` — MEDIUM
- **Source**: pitchgen.quick.shopify.io (Andrei Dumitriu)
- **What**: AI-powered sales deck narrative generation with slide search/preview
- **Pattern**: Quick frontend + Cloud Run API backend (separate infra)
- **Stage**: Evaluate & Decide
- **Action**: Lower priority — requires backend infra beyond Pi/Claude. Park until we need presentation automation

### 5. `merchant-health-report` — MEDIUM
- **Source**: prepdesk.quick.shopify.io (Carla Paige, Growth Advisory)
- **What**: Automated merchant analysis → Google Doc. Highest volume tool found (10+ reports/day in #prep-desk)
- **Pattern**: BigQuery merchant data → AI synthesis → formatted Google Doc output
- **Stage**: Evaluate & Decide
- **Action**: Adapt for MM/ENT audience. Our `account-research` skill covers similar ground — compare BQ queries

---

## 🔧 Existing Skill Enrichments (from ecosystem patterns)

### 6. `context-handoff` — Enrich with Context Vault patterns
- **Source**: context-vault.quick.shopify.io (Selling Strategies team)
- **What they built**: Manual file sharing tool (GSD team folders, PDF/MD/Doc upload, markdown conversion, team privacy toggle)
- **Our approach should be different**: Auto-pull context from SF/Slack/emails and package for next person — not just a file dump
- **Action**: Study their UX for the "what to share" taxonomy (team context, topic context, individual files). Keep our automated approach but consider adding manual upload as a fallback

### 7. `meeting-capture` — Study Meeting Actions implementation
- **Source**: meeting-actions.quick.shopify.io (Mark Roche)
- **What they built**: Pull action items from Google Meet transcripts, structured checklists by owner, sortable by urgency, copy to Slack/Fellow
- **Action**: Visit the site, test with a real transcript, see what the output format looks like. Build our skill to match or exceed

### 8. `meeting-prep` — Add "external research" mode
- **Source**: call-prep.quick.shopify.io pattern
- **Current**: Our skill uses BigQuery/Salesforce for existing deals
- **Gap**: No coverage for net-new prospects (first meeting, no SF data)
- **Action**: Add a mode that falls back to Perplexity web research when no internal data exists

### 9. `opp-hygiene` — Add AI-driven RoE validation
- **Source**: oppcheckr.quick.shopify.io pattern
- **Current**: Our skill has manual assessment patterns
- **Gap**: Could automate compliance checking against actual RoE document
- **Action**: Get the Consolidated Revenue RoE text, build an automated check mode

### 10. `account-research` — Validate BQ queries against Prep Desk
- **Source**: prepdesk.quick.shopify.io (high-volume production)
- **Current**: Our skill has 49 validated BQ queries
- **Gap**: Prep Desk may use different/better data sources for CRO, conversion, SEO analysis
- **Action**: Compare our `merchant-analytics-queries` with Prep Desk's BQ queries (they use copilot_descriptive_data table + others)

### 11. `competitive-positioning` — Add periodic digest format
- **Source**: competitive-intel-digest.quick.shopify.io (Kristina Augustinaite)
- **Current**: Our skill is on-demand competitive analysis
- **Gap**: No time-based "what changed this week" digest
- **Action**: Consider adding a weekly competitor update mode that summarizes recent competitive moves

---

## 📌 Other Notable Quick Sites (Reference Only)

| Site | Owner | What | Why Notable |
|---|---|---|---|
| strategic-prospect-planner | EMEA SA | Static per-account BoB dashboards | Pre-generated from CSV, simple but effective |
| Matchie (#customer-references) | Génesis Miranda Longo | Customer reference matching | 290 requests, 110 users/month — highest adoption |
| growth.quick.shopify.io | Unknown | Merchant conversation practice | AI roleplay for advisory |
| CoachAI.quick.shopify.io | Nicholas Wilson | Leadership coaching | AI coaching pattern |
| sales-comp-calculator | Henry Springer | Commission simulator | 12-quarter sim |
| arizona-field-sales-crm | John Sime | Field sales CRM with map | Regional tool |
| Salesloft Cadence Backup | Susann Fuhrmann | Gumloop agent for CRM migration | Timely — CRM move happening |
| Launchpad | (automated) | AI tool catalogue | Auto-detects new tools in Slack |
| Growth Services Brain | Galen King | 72 commands + 28 rules | Most mature agent setup found |

---

## 🆕 New Skill Ideas (from Quick MCP Scan v2 — March 12, 2026)

### 12. `qualification-trainer` ⭐ HIGH — ✅ BUILT (2026-03-12)
- **Source**: qualification.quick.shopify.io + company-lookup.quick.shopify.io (UAL)
- **What**: Interactive roleplay — choose role/segment/difficulty → AI generates scenario (optionally with real UAL account data) → user practices discovery → AI evaluates with MEDDPICC scorecard + hidden context reveal
- **Installed**: ~/.pi/agent-shopify/skills/ + ~/.claude/skills/ (180 lines)
- **Key feature**: NEW CATEGORY (Training/Practice). 3 difficulty levels, pre-built scenario library by segment, role-specific evaluation criteria

### 13. `merchant-growth-advisor` ⭐ HIGH
- **Source**: spotlight.quick.shopify.io + revenue-goldmine.quick.shopify.io
- **What**: Takes a merchant shop ID/URL → generates personalized growth recommendations. Spotlight is evidence-based for support advisors. Revenue-goldmine has checkout feature → revenue uplift mapping (one-page checkout +12-18%, checkout blocks +8-25%, etc.)
- **Updated**: Mar 12, 2026 (Spotlight — active today!) / Mar 10 (Revenue Goldmine)
- **Stage**: Growth & Optimization
- **Action**: Combine patterns — use account-research BQ queries to get merchant context, then map to feature recommendations using revenue-goldmine's uplift data. Build as a Pi skill

### 14. `churn-intelligence` — MEDIUM
- **Source**: temp-hd-merch-jouney-melz.quick.shopify.io (Melanie Zieba, Hack Days 39)
- **What**: End-to-end merchant lifecycle mapping with churn POC. Found 484 merchants, $156M GMV, $27.9M recoverable. 92% dead merchants had zero support contact, 90% had no service model
- **Updated**: Feb 2026
- **Stage**: At Risk & Recovery
- **Action**: Their data validates our blind spots. Study their "Where Are They Now?" view for win-back patterns. Could power an early-warning system

### 15. `team-coaching-analytics` — MEDIUM
- **Source**: GS-call-coaching.quick.shopify.io
- **What**: BigQuery-powered team-level call transcript analysis. Scores reps, identifies coaching areas across full roster with time range filters
- **Updated**: Jan 28, 2026 (78KB)
- **Stage**: Decision & Purchase
- **Action**: Our `sales-call-coach` does single-call scoring. This adds the manager view — patterns across a team's calls. Study their BQ queries for transcript analysis

### 16. `vertical-battle-cards` — MEDIUM
- **Source**: cg-sales-enablement.quick.shopify.io
- **What**: Industry-specific enablement with market data ($957B Home Furnishings by 2032), case studies with "what closed the deal" stories, and vertical-specific competitive intel
- **Updated**: Recent (indexed/searchable)
- **Stage**: Awareness & Evaluation
- **Action**: Our `competitive-positioning` is platform-vs-platform. This adds the industry lens. Template the CG pattern for other verticals

## 🔧 Additional Enrichments (from Quick MCP Scan v2)

### 17. `sales-call-coach` — Add team-level analytics
- **Source**: GS-call-coaching.quick.shopify.io
- **Enrichment**: Add a "manager mode" that analyzes patterns across a team's calls, not just individual post-call scoring

### 18. `account-research` — Add recommendation generation
- **Source**: spotlight.quick.shopify.io
- **Enrichment**: After running data analysis, generate "here's what you should recommend" — not just raw data. Support → Sales bridge framing

### 19. `sales-manager-dashboard` — Regional templating
- **Source**: emea-sales-dashboard.quick.shopify.io (nerissa_c, Mar 5, 2026)
- **Enrichment**: Confirm the template pattern works for non-AMER orgs. Same `rev_ops_prod.temp_sales_performance` table, just different region filters

### 20. `account-context-sync` — Structured context categories
- **Source**: retail-buyer-journey-planner.quick.shopify.io
- **Enrichment**: Add typed context entries (Tech Limits, Product Briefs, Data Explorations, Findings) instead of flat context dump

### 21. `competitive-positioning` — Industry-specific framing
- **Source**: cg-sales-enablement.quick.shopify.io
- **Enrichment**: Add vertical market data, industry-specific case studies, and "what's top of mind for X brands" framing

### 22. 🔑 CROSS-CUTTING: UAL + SF Account Lookup (company-lookup.quick.shopify.io)
- **Source**: company-lookup.quick.shopify.io ("Dupe Checker")
- **Reference doc**: `references/company-lookup-ual-query.md` — full SQL + field mapping
- **Data sources**:
  - `sdp-prd-commercial.mart.unified_account_list` — master account dedup (4 name sources, 4 domain sources, 3 owner sources, territory)
  - `shopify-dw.raw_salesforce_banff.account` + `website__c` + `user` — SF account/domain/owner lookup
- **Fuzzy matching**: Domain normalization (strip protocol/www/path), tiered scoring (exact=100, root=85, subdomain=80, starts_with=85, contains=70)
- **Enriches these skills**:
  - `prospect-researcher` — pre-check UAL before external research to avoid stepping on existing accounts
  - `opp-compliance-checker` — territory/ownership validation against UAL
  - `opp-hygiene` — dupe detection across UAL + SF accounts
  - `account-research` — resolve domain/shop_id → account + owner + territory
  - `meeting-prep` — account ownership enrichment before calls
  - `deal-followup` — confirm account details for follow-ups
  - `qualification-trainer` — realistic account data for training scenarios
- **Action**: Add a reusable `lookupAccount(name, domain, shopId)` BQ function to the shared query library that any skill can call. This is a foundational data primitive.

---

## 📌 Other Notable Quick Sites — v2 Additions (Reference Only)

| Site | Updated | Owner | What | Why Notable |
|---|---|---|---|---|
| post-sales-dashboard | Mar 6, 2026 | Rev Ops Reporting team | Post-sales: accounts, onboarding, NRR, launch cases | Revenue Tools team's own Quick dashboard (migrated from Looker) |
| rev-funnel-ops | Mar 10, 2026 | Rev Ops Reporting team | Full funnel: leads → SAL → CW with YoY, 1.1MB index | Massive reference dashboard — same data source as diana-dashboard |
| agentic-roadmaps-wireframes | Feb 14, 2026 | Hack Days 39 | AI roadmap generator for Ops teams | Agentic pattern for roadmap planning |
| revenue-analytics-context | Mar 3, 2026 | Unknown | Eval of revenue_analytics_context.md impact on agent accuracy | Meta-tool: measures how context docs improve AI revenue queries |
| sales-mock-and-role | Feb 12, 2026 | Unknown | SDR outbound call roleplay trainer | Another training tool — roleplay against AI-simulated prospects |
| incentive-compensation-tool | Mar 11, 2026 | Unknown (CSM) | CSM self-service comp/attainment dashboard | Clean Quick+BQ pattern with detailed README |
| attainmentleaderboard2026 | Feb 20, 2026 | Unknown | Gamified attainment leaderboard (space theme) | Uses same RPI tables as diana-dashboard |
| checkout-analyzer | Feb 27, 2026 | Unknown | Drag-drop checkout log analyzer | Client-side only, great triage pattern |
| quickrank | Mar 10, 2026 | atesgoral | Slack-mention-based Quick site ranking | Meta-tool: discovers popular Quick sites |

---

## 📊 Quick Directory Access Notes
- **CLI**: `quick mcp directory` exposes: `list_collections`, `query_collection`, `get_object`, `search_site`, `search_global`, `list_searchable_sites`
- **Collections**: `sites` (2,508 entries), `posts`, `__quicklytics`, `__quickthoughts`
- **Freshness issue**: DB indexed Sept 2025 — newer sites (Feb-Mar 2026) NOT in DB, found only via Slack
- **For individual sites**: `quick mcp <sitename>` gives file listing + content access
