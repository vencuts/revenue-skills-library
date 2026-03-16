# Smoke Signals — Signal-Based Sales Intelligence

Source: https://smokesignals.quick.shopify.io/
Extracted: 2026-03-12
Updated: 2026-03-10 (663 bytes SPA + 267KB JS bundle)

## What It Is
Full signal-based sales intelligence platform for SDRs. Pulls accounts by territory from BQ, then for each account:
1. Fetches SEC EDGAR filings (10-K, 10-Q, 8-K, S-1) from the last 12 months
2. Fetches news articles
3. Pulls first-party Shopify engagement data (trials, events, webinars, closed-lost opps)
4. AI scores and stacks all signals into a buying story
5. Generates personalized outreach frameworks with signal-referenced hooks

## BQ Tables — VALIDATED 2026-03-12

### Table Lineage (verified via BQ schema + row count comparison)

The `sales.*` tables are **enriched mart layers** built on top of `base__salesforce_banff_*`. Same Salesforce source data, identical row counts (120K opps, 1M accounts), identical `updated_at` timestamps. Base has 7 more opps and 151 more accounts (includes soft-deleted records).

**Strategy: Keep `base__*` as canonical, use `sales.*` only for enriched fields.**

### Enriched Mart Tables (same data as base, with extra columns)

| Table | What | Use For | Extra vs Base |
|-------|------|---------|---------------|
| `shopify-dw.sales.sales_accounts_v1` | Account master — enriched | Enriched account context | 34 extra cols: `account_priority_{d2c,retail,b2b,ads,lending,csm}`, `domain_clean`, `account_owner` (resolved name), `territory_{region,segment,subregion,sales_motion}`, `primary_shop_id`, `primary_contact_email`, `merchant_success_manager` + email, `related_domains`, `salesloft1_*` |
| `shopify-dw.sales.sales_opportunities` | Opps — enriched | Enriched opp context | Extra: `compelling_event`, `market_segment`, `team_segment`, `territory_name`, `salesforce_owner_name`, `forecast_category`, `region/subregion`, `description`, `next_step` |

### Truly NEW Tables (not available in base)

| Table | What | Use For |
|-------|------|---------|
| `shopify-dw.sales.shop_to_sales_account_mapping` | Shop ID -> SF Account ID bridge | Joining Shopify product data to SF commercial data. THE missing link. |
| `shopify-dw.accounts_and_administration.shop_subscription_milestones` | Trial events (free_trial_started, paid_trial, first_paid) | Trial signal detection |
| `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` | Campaign/event/webinar touchpoints with interaction status | Engagement signal detection |

## Signal Scoring System

### Tier 1 — Immediate (highest value)
| Signal | Points | Notes |
|--------|:------:|-------|
| Closed lost Shopify opportunity | 60 | Highest re-engagement signal. Surface why they didn't buy, what changed |
| Shopify paid trial started | 50 | Direct platform evaluation — highest urgency |
| Past champion job change | 50 | Contact moved companies |
| New exec hire (CTO/CEO/CRO/VP) | 40 | New decision-maker |
| Shopify free trial started | 40 | Active product evaluation |
| Funding/IPO | 35 | Capital available |
| Active vendor evaluation | 35 | In-market now |

### Tier 2 — Priority
| Signal | Points | Notes |
|--------|:------:|-------|
| Shopify webinar/event attended | 25 | Engaged with Shopify brand |
| Hiring surge (5+ relevant roles) | 25 | Building digital team |
| Earnings call language match | 25 | ecommerce/digital/DTC mentioned |
| 10-K strategic priority match | 25 | Ecommerce in strategic priorities |
| M&A activity | 20 | Business transformation |
| Product launch/new market | 20 | Growth mode |
| Webinar/event registered (no attendance) | 15 | Interested but didn't show |
| Press release / company news | 15 | Context |

### Tier 3 — Watch
| Signal | Points | Notes |
|--------|:------:|-------|
| Industry trend relevance | 10 | Macro signal |
| Geopolitical/macro impact | 10 | External factor |

### Urgency Thresholds
- **Hot**: 80+ pts
- **Warm**: 50-79 pts
- **Developing**: 25-49 pts
- **Watch**: < 25 pts

### Key Rule
Open (active) opportunities are NOT scored — excluded from signals, shown as greyed-out context.

## AI Output Schema

```json
{
  "signals": [{ "id", "type", "tier", "title", "description", "date", "points", "source", "url" }],
  "totalScore": 75,
  "urgency": "warm",
  "stackAnalysis": "2-3 sentence narrative connecting signals into a buying story",
  "hypotheses": ["hypothesis 1", "hypothesis 2"],
  "recommendedContacts": [{ "title": "VP Ecommerce", "reason": "why based on signals", "channel": "email" }],
  "outreachFrameworks": [{
    "name": "Angle name",
    "signalReference": "which signal(s) this uses",
    "opening": "1-2 sentence hook that references the signal naturally",
    "hypothesis": "the business challenge this implies",
    "valueBridge": "how Shopify Plus connects to this",
    "cta": "low-friction ask (share resource, not book a demo)",
    "channel": "email|linkedin|phone"
  }],
  "followUpTriggers": ["monitor for X", "re-engage if Y"]
}
```

## External Data Sources
- **SEC EDGAR**: `https://efts.sec.gov/LATEST/search-index` — 10-K, 10-Q, 8-K, S-1 filings (12-month lookback)
- **News**: Via API (allorigins proxy for CORS)
- **LinkedIn**: Implied by champion job change + exec hire signals (manual or API)

## Skills This Powers

| Skill | What to Use | NOT |
|-------|------------|-----|
| `signal-monitor` (parking lot #2) | 3 new tables + scoring system + outreach framework | Don't use sales.* for core opp/account data — use base.* |
| `prospect-researcher` | `sales_accounts_v1` for enriched context (priority, platform, domain_clean) + `shop_to_sales_account_mapping` for existing shop detection | Don't replace UAL ownership check |
| `meeting-prep` | All 3 new tables (trial + campaign + shop mapping) + `sales_accounts_v1` enrichments | Keep base.* for opp data |
| `account-research` | `shop_to_sales_account_mapping` for multi-shop resolution + `sales_accounts_v1` for header context | Keep existing shop_id resolution |
| `deal-prioritization` | Signal urgency scoring + `sales_accounts_v1` grade/priority | Keep base.* opp amounts |
| `opp-hygiene` | `sales_opportunities.compelling_event` check + closed-lost re-engagement | Keep base.* as canonical |
| `competitive-positioning` | `sales_accounts_v1.ecomm_platform` for auto battle card selection | — |
| NEW: `outreach-generator` | Outreach framework generation pattern | — |
