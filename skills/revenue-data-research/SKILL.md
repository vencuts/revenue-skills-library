---
name: revenue-data-research
description: Auto-activates for any Shopify revenue data analysis — closed-lost, pipeline, attainment, activity, engagement, win/loss, territory, forecasting, or ad-hoc BQ research. Loads all known table schemas, runs data-integrity-check first, then builds and executes queries. Triggers on "analyze", "closed lost", "pipeline", "attainment", "quota", "win rate", "loss analysis", "deal velocity", "activity report", "engagement", "forecast", "cohort", "retention", "churn", "territory coverage", "rep performance", "funnel", or any request involving Salesforce, UAL, Salesloft, or revenue BigQuery data.
---

# Revenue Data Research

> **This skill fires automatically whenever you ask a data question about revenue, deals, pipeline, or rep performance.** It knows every BQ table the Revenue Skills Library has cataloged.

## Step 0: Data Integrity Pre-Flight

Before running ANY query involving a specific account, opp, or rep:
- Run `data-integrity-check` on the entity
- If confidence LOW → warn user before presenting results: "⚠️ Data quality issues detected — see warnings below. Results may be affected."
- If analyzing a PORTFOLIO (e.g., all closed-lost this quarter) → skip per-entity integrity check, but note: "Portfolio analysis — individual account data quality not validated."

## Step 1: Identify Research Type and Route to Tables

```
User asks about...
│
├── Closed-lost / win-loss analysis
│   → Primary: base__salesforce_banff_opportunities (filter: stage = 'Closed Lost' or 'Closed Won')
│   → Join: base__salesforce_banff_accounts (account name context)
│   → Join: base__salesforce_banff_users (rep lookup)
│   → Enrichment: salesforce_activity (engagement signals)
│   → Enrichment: base__salesloft_conversations_extensive (call transcripts, AI summaries)
│   → Enrichment: report_revenue_reporting_sprint_billed_revenue_cohort (PBR at opp grain)
│
├── Pipeline / forecast / attainment
│   → Primary: RPI_base_attainment_with_billed_events (quota, attainment, projected per worker)
│   → Join: base__salesforce_banff_opportunities (open opps, stages, amounts)
│   → Filter: closed opps by close_date, open opps by created_at (matches AMER Performance Dashboard)
│
├── Activity / engagement analysis
│   → Primary: salesforce_activity (opp + account level signals)
│   → Enrichment: base__salesloft_conversations_extensive (call data)
│   → Enrichment: raw_salesforce_banff.task (SDR notes, email bodies — Reply: = merchant, Email: = outbound)
│   → Engagement tiers: ghost (0 signals) → account-only → outreach → contact → meetings
│
├── Territory / coverage
│   → Primary: unified_account_list (UAL — canonical)
│   → Territory tables: TI_* scratch tables (16 tables)
│   → Worker attributes: worker_current_null_sales_attributes
│
├── Rep performance / coaching
│   → Primary: RPI_base_attainment_with_billed_events
│   → Join: base__salesloft_conversations_extensive (call quality)
│   → Join: salesforce_activity (activity volume)
│
├── Transcript / call analysis
│   → Primary: base__salesloft_conversations_extensive (transcripts, AI summaries, MEDDPICC)
│   → Bridge: sales_calls_to_opportunity_matching (event_id → opp_id, ~40% coverage)
│   → Fallback: base__salesloft_people → base__salesloft_accounts (email → account chain)
│
└── Ad-hoc / custom query
    → Ask what data they need, consult Table Reference below, build query
```

## Step 2: Build and Execute Query

Use `query_bq` with fully-qualified table names. Always:
- Use parameterized queries with `@param` syntax
- LIMIT results (500 max enforced)
- Date-scope queries to avoid pulling years of irrelevant data
- For closed opps: filter by `close_date`
- For open opps: filter by `created_at`
- For activity on closed opps: pull ALL-TIME activity (time filter determines which opps, not what activity)

## Step 3: Interpret Results

Don't just return raw numbers. For every analysis:
- **Context**: Compare to benchmarks (team avg, segment avg, prior period)
- **Patterns**: Call out outliers, trends, clusters
- **Warnings**: Note data quality issues from Step 0
- **Actions**: Suggest specific next steps based on findings
- If PBR data exists (closed-won only), prefer PBR over SF Amount for revenue figures
- If PBR is null (open/lost opps), fall back to SF Amount — note this in output

## Table Reference (fully-qualified names)

### Salesforce Core
| Table | Key Fields | Notes |
|-------|-----------|-------|
| `shopify-dw.base.base__salesforce_banff_opportunities` | opportunity_id, account_id, stage, amount, close_date, created_at, owner_id, primary_product_interest | Main opp table |
| `shopify-dw.base.base__salesforce_banff_accounts` | account_id, account_name, website, owner_id | Account context |
| `shopify-dw.base.base__salesforce_banff_users` | user_id, name, email | SF user lookup |
| `shopify-dw.raw_salesforce_banff.task` | WhatId (opp), AccountId, Subject, Description | SDR notes/emails. `Reply:` = merchant voice, `Email:` = Shopify outbound |

### Revenue Reporting
| Table | Key Fields | Notes |
|-------|-----------|-------|
| `sdp-for-analysts-platform.rev_ops_prod.report_revenue_reporting_sprint_billed_revenue_cohort` | opportunity_id, billed_revenue | PBR at opp grain. Join on opportunity_id, filter months_since_close = 0 |
| `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events` | worker_email, quota, attainment, projected_revenue | Quota + attainment per worker |
| `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity` | opportunity_id, account_id | Activity signals at opp + account level |

### Salesloft
| Table | Key Fields | Notes |
|-------|-----------|-------|
| `shopify-dw.base.base__salesloft_conversations_extensive` | conversation_id, transcript, ai_summary, attendees, meddpicc | One row per call. Full transcripts + AI summaries |
| `shopify-dw.intermediate.sales_calls_to_opportunity_matching` | event_id, most_recent_salesforce_opportunity_id | Bridge: call → opp (~40% coverage) |
| `shopify-dw.base.base__salesloft_people` | email_address, account.id, crm_id | Person → account chain |
| `shopify-dw.base.base__salesloft_accounts` | salesloft_account_id, crm_id | crm_id = SF account_id |

### UAL & Data Quality
| Table | Key Fields | Notes |
|-------|-----------|-------|
| `sdp-prd-commercial.mart.unified_account_list` | account_id, account_name, region, service_model, fit scores, revenue estimates | THE canonical account list |
| `shopify-dw.scratch.UAL_data_quality_check_SP_null_{field}` | account_id | 20 tables, one per null field |
| `shopify-dw.scratch.TI_{check}` | territory_id | 16 territory health tables |
| `shopify-dw.scratch.worker_current_null_sales_attributes_where_sales_team_not_null` | worker_email | Missing rep attributes |

### Vault / Centaur
| Table | Key Fields | Notes |
|-------|-----------|-------|
| `shopify-project-centaur.centaur.vault_users_v1` | user_id, name, email, team_id, github, slack_handle | People lookup |
| `shopify-project-centaur.centaur.vault_teams_v1` | team_id, name, parent_id | Team hierarchy |

### ⛔ Access Denied
| Table | Issue |
|-------|-------|
| `sdp-prd-commercial.intermediate.*` | 403 — do NOT query |

## Error Handling

| Scenario | Response |
|----------|----------|
| Table returns 403 | "Cannot access [table] — need [project] permissions. Falling back to [alternative]." |
| Query returns 0 rows | "No data found for [filter]. Check: date range too narrow? Account name spelling? Try broader filter." |
| Query timeout | Simplify query — remove JOINs, narrow date range, add LIMIT. |
| User asks about a table not in reference | Check INFORMATION_SCHEMA first: `SELECT table_name FROM \`project.dataset.INFORMATION_SCHEMA.TABLES\` WHERE table_name LIKE '%keyword%'` |
| PBR data missing for closed-won | "PBR not available — using SF Amount. Note: PBR is the source of truth for billed revenue." |
| Transcript coverage gap | "Only X of Y logged calls have transcripts. Analysis based on available transcripts — actual patterns may differ." |

## Scope Boundaries

- This skill queries and analyzes data. It does NOT write to Salesforce (use `sf-writer` for that).
- For per-account deep research, hand off to `account-research`.
- For competitive context, hand off to `competitive-positioning`.
- For call coaching, hand off to `sales-call-coach`.
- **Domain vocabulary**: PBR (Projected Billed Revenue), UAL (Unified Account List), CW (Closed Won), CL (Closed Lost), ACV (Annual Contract Value), GMV (Gross Merchandise Value), ARR (Annual Recurring Revenue), QTD (Quarter-to-Date), YTD (Year-to-Date), MoM (Month-over-Month), WoW (Week-over-Week), SAL (Sales Accepted Lead), SQL (Sales Qualified Lead), MQL (Marketing Qualified Lead), LOB (Line of Business), MSM (Merchant Success Manager), SDR (Sales Development Rep), AE (Account Executive), SE (Solutions Engineer), CSM (Customer Success Manager)
