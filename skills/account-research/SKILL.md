---
name: account-research
description: BigQuery-powered merchant/account analysis using a validated query library of 49 SQL queries. Supports conversion, acquisition, catalog, app ecosystem, content, behavior, performance (Core Web Vitals), retention, and customer lifecycle research. Use when asked to "research [merchant]", "analyze conversion", "run app audit", "catalog analysis", "traffic breakdown", "bounce rate", "funnel analysis", "device performance", "retention cohorts", or any merchant data analysis. Works for AEs, SEs, Rev Ops, Growth — anyone needing data-driven account insights.
---

# Account Research

BigQuery-powered merchant analysis using a validated, production-tested query library. Each query has been verified against official Shopify data sources.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Execute all merchant analytics queries, UAL lookup, account context | This skill is non-functional without BQ. Tell user: "BigQuery access required. Request via #help-data-platform or use Data Portal console directly." |
| `perplexity_search` | Industry benchmarks for comparison (e.g., "average ecommerce CR for {industry}") | Provide Shopify internal benchmarks only; note external comparison unavailable |
| `vault_search` | Internal playbooks, team context for the account's territory | Skip territory context; focus on data analysis only |

**Critical dependency: `query_bq` is required.** Unlike other skills that gracefully degrade, this skill's core value IS the queries. Without BQ access, redirect user to `merchant-analytics-queries` skill for manual SQL execution.

---

## Workflow

### Step 0: Data Integrity Pre-Flight

If the user provides an account name, ID, or domain, run `data-integrity-check` before any research queries. If duplicate accounts exist, clarify which one to research. If UAL fields are null (region, fit scores, revenue estimates), note in your output: "⚠️ UAL data incomplete — [field] is null. Research findings below may lack segment context." This prevents building analysis on empty data.

### Step 1: Identify Research Type

Map the user's request to a research type:

| Natural Language | Research Type | Primary Queries |
|---|---|---|
| "conversion analysis", "funnel", "checkout" | conversion | `cro-signals-cr-with-benchmark-90d`, `cro-signals-purchase-funnel` |
| "traffic", "acquisition", "referrers", "channels" | acquisition | `cro-signals-referrers`, `marketing-channel-attribution` |
| "app audit", "installed apps", "app ecosystem" | apps | `app-audit-canonical` |
| "catalog", "products", "inventory", "variants" | catalog | `product-catalog-analysis`, `comprehensive-catalog-analysis` |
| "bounce rate", "engagement" | behavior | `cro-signals-bounce-rate-by-page-type`, `bounce-rate-benchmarking` |
| "device", "mobile", "desktop" | devices | `cro-signals-devices-form-factor`, `cro-signals-devices-os` |
| "performance", "web vitals", "speed", "LCP" | performance | `perf-rum-aggregation`, `perf-suspicious-traffic` |
| "search", "site search" | search | `cro-signals-searches` |
| "customer", "retention", "lifecycle" | customer | `customer-lifecycle-behavior`, `retention-cohort-analysis` |
| "historical", "trends", "over time" | trends | `cro-signals-cr-over-time`, `metrics-trend-analysis` |
| "content audit", "navigation", "theme" | content | `content-audit-navigation-analysis`, `content-audit-theme-architecture` |
| "landing pages" | landing | `landing-page-analysis` |
| "comprehensive", "full research", "everything" | comprehensive | Run multiple types in sequence |

If ambiguous, ask: "What aspect? Options: conversion, acquisition, apps, catalog, devices, performance, behavior, customer lifecycle, retention, or comprehensive."

### Step 2: Resolve Shop ID + Account Context

**First, run UAL lookup** to get account ownership, territory, and SF Account ID:

```sql
SELECT
  COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
  COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
  territory_name,
  COALESCE(domain, domain_sf, domain_3p, domain_1p) AS best_domain,
  account_id AS sf_account_id
FROM `sdp-prd-commercial.mart.unified_account_list`
WHERE LOWER(COALESCE(domain, domain_sf, domain_3p, domain_1p))
      LIKE CONCAT('%', LOWER(@search_domain), '%')
   OR LOWER(COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p))
      LIKE LOWER(@search_name)
LIMIT 10
```

**Domain normalization** — strip protocol/www/path for matching:
```sql
LOWER(REGEXP_REPLACE(IFNULL(domain, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3'))
```

**Then pull enriched commercial context** (34 extra fields not in base):

```sql
SELECT a.industry, a.annual_total_revenue_usd AS revenue, a.ecomm_platform,
  a.account_grade, a.account_priority_d2c AS priority, a.sales_lifecycle_stage,
  a.plus_status, a.number_of_employees, a.primary_shop_id, a.domain_clean,
  a.merchant_success_manager, a.territory_name, a.territory_segment, a.account_owner
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.account_id = @sf_account_id
LIMIT 1
```

**Multi-shop resolution** — enterprise accounts can have multiple shops:

```sql
SELECT sam.shop_id, sam.salesforce_account_id
FROM `shopify-dw.sales.shop_to_sales_account_mapping` sam
WHERE sam.salesforce_account_id = @sf_account_id
```

If multiple shops found, run analytics queries across ALL of them (use `shop_id IN (...)` instead of single shop_id).

Then resolve shop ID:
1. If user provides shop ID → use directly
2. If user provides domain → run `shop-identification-by-domain` query
3. If user provides merchant name → UAL lookup first (gets domain + SF context), then resolve shop ID from domain
4. If UAL returns an account → include owner, territory, SF Account ID in the output header
5. **If `shop_to_sales_account_mapping` returns multiple shops** → flag multi-shop account, run analytics across all

### Step 3: Execute Queries

Load the appropriate SQL from `queries/` directory, replace `SHOP_ID_HERE` with resolved shop ID, execute via BigQuery.

**Execution rules:**
- Always validate cost before running (use `agent-data` dry-run if available)
- Run queries in parallel when they're independent
- For "comprehensive" research, run in this order: identification → conversion → acquisition → devices → behavior → catalog → apps → performance

### Step 4: Synthesize Findings

Structure output as:

```
## 📊 Account Research: [Merchant Name]
**Shop ID:** [ID] | **Domain:** [domain] | **Created:** [date]
**Account Owner:** [from UAL] | **Territory:** [from UAL] | **SF Account:** [ID]
**Grade:** [A/B/C/D] | **Priority:** [High/Med/Low] | **Lifecycle:** [stage]
**Platform:** [ecomm_platform] | **Plus:** [status] | **Shops:** [N shops found]
**Industry:** [industry] | **Revenue:** $[X] | **Employees:** [N]
**CSM:** [name or N/A] | **Segment:** [territory_segment]
**Research Type:** [type] | **Data Period:** [range]

### TL;DR
[2-3 sentence executive summary — the single most important finding]

### Key Metrics
| Metric | Value | Benchmark | Status |
|---|---|---|---|
| [Metric] | [Value] | [Industry avg] | 🟢/🟡/🔴 |

### Findings
[Detailed analysis organized by research type]

### Recommendations
1. [Actionable recommendation grounded in data]
2. [Recommendation]

### Data Sources
[List of queries executed with row counts]
```

---

## Query Library Reference

### Account Identification (UAL + SF)
| Query | Purpose |
|---|---|
| `ual-account-lookup` | Resolve company name/domain/shop_id → account owner, territory, SF Account ID via `sdp-prd-commercial.mart.unified_account_list` |
| `sf-website-account-lookup` | Fallback: domain → account via `shopify-dw.raw_salesforce_banff.website__c` joined to `account` + `user` |
| `shop-identification-by-domain` | Find shop_id from domain/name |

### Conversion & Funnel
| Query | Purpose |
|---|---|
| `cro-signals-cr-with-benchmark-90d` | Conversion rate with industry benchmarks (90d) |
| `cro-signals-purchase-funnel` | Raw funnel data by device and landing page type |
| `improved-purchase-funnel-analysis` | Enhanced funnel with step-by-step drop-off |
| `conversion-benchmarking-90d` | Conversion benchmarking |
| `detailed-conversion-aov-benchmarking` | Conversion + AOV combined |
| `cro-signals-aov-cr-benchmarking` | AOV and CR signals |
| `cro-signals-orders-trend` | Order volume trends |

### Traffic & Acquisition
| Query | Purpose |
|---|---|
| `cro-signals-referrers` | Traffic sources and referrers |
| `marketing-channel-attribution` | Marketing channel attribution |
| `traffic-source-crisis-analysis` | Diagnose sudden traffic drops |
| `landing-page-analysis` | Landing page performance |

### Behavior & Engagement
| Query | Purpose |
|---|---|
| `cro-signals-bounce-rate-by-page-type` | Bounce rate broken down by page type |
| `bounce-rate-benchmarking` | Bounce rate vs benchmarks |
| `session-engagement-analysis` | Session depth and engagement |
| `cro-signals-searches` | Site search usage and terms |

### Devices & Browsers
| Query | Purpose |
|---|---|
| `cro-signals-devices-form-factor` | Mobile vs desktop vs tablet |
| `cro-signals-devices-os` | Operating system breakdown |
| `cro-signals-devices-browsers` | Browser breakdown |
| `cro-signals-devices-raw` | Raw device data |
| `device-performance-breakdown` | Performance by device type |

### Catalog & Inventory
| Query | Purpose |
|---|---|
| `product-catalog-analysis` | Product catalog structure |
| `comprehensive-catalog-analysis` | Deep catalog analysis |
| `comprehensive-catalog-overview` | Catalog overview |
| `catalog-architecture-analysis` | Catalog architecture |
| `current-inventory-levels` | Current inventory snapshot |
| `inventory-value-analysis` | Inventory value analysis |

### Apps
| Query | Purpose |
|---|---|
| `app-audit-canonical` | Complete app install audit with billing and permissions |
| `merchant-app-audit` | App audit (original) |
| `merchant-app-audit-corrected` | App audit (corrected) |
| `merchant-app-audit-optimized` | App audit (optimized) |

### Performance (Core Web Vitals)
| Query | Purpose |
|---|---|
| `perf-rum-aggregation` | TTFB, FCP, LCP, INP, CLS by device with percentiles |
| `perf-suspicious-traffic` | Detect bot/suspicious traffic patterns |

### Customer Lifecycle
| Query | Purpose |
|---|---|
| `customer-lifecycle-behavior` | New vs returning visitor comparison |
| `retention-cohort-analysis` | Visitor return frequency and retention |

### Content & Theme
| Query | Purpose |
|---|---|
| `content-audit-navigation-analysis` | Navigation structure audit |
| `content-audit-product-richness` | Product content quality |
| `content-audit-theme-architecture` | Theme architecture analysis |

### Trends & Historical
| Query | Purpose |
|---|---|
| `cro-signals-cr-over-time` | Conversion rate trends |
| `metrics-trend-analysis` | Multi-metric trend analysis |
| `temporal-trend-analysis` | Temporal patterns (day of week, time of day) |
| `historical-sales-performance-periods` | Historical sales performance |
| `comprehensive-metrics-diagnostic` | Diagnostic multi-metric view |

### Salesforce / Salesloft
| Query | Purpose |
|---|---|
| `salesloft-emails-by-merchant` | Salesloft email activity for a merchant |

---

## Key BigQuery Tables

| Table | Content |
|---|---|
| `shopify-dw.accounts_and_administration.shop_profile_current` | Shop profiles (domain, country, currency) |
| `shopify-dw.buyer_activity.storefront_sessions_summary_v3` | Session-level storefront data |
| `shopify-dw.intermediate.app_install_permission_state_events_v1` | App install/uninstall events |
| `shopify-dw.intermediate.partner_billings` | App billing data |
| `sdp-for-analysts-platform.growth_services_prod.purchase_funnel_new` | Official purchase funnel |
| `sdp-prd-commercial.mart.unified_account_list` | Master account dedup (UAL) — ownership, territory, multi-source matching |
| `shopify-dw.raw_salesforce_banff.website__c` | SF website records — domain → account + shop_id mapping |

---

## Output Format

Shape output based on research type:

### Single Research Type (conversion, apps, catalog, etc.)
- **TL;DR**: 2-3 sentence executive summary with key finding + benchmark comparison
- **Data Table**: Key metrics from query results with context
- **Interpretation**: What the data means for this merchant specifically
- **Recommendation**: 1-2 actionable next steps based on findings

### Comprehensive Research
- **Executive Summary**: 5-7 sentence overview across all dimensions
- **Section per research type**: Each with its own data + interpretation
- **Cross-Dimensional Insights**: "Low mobile CR (1.2%) combined with high mobile traffic (68%) = $X revenue leakage"
- **Priority Recommendations**: Top 3 actions ranked by expected impact

### When Data Is Sparse (< 100 sessions or < 30 days)
- Add banner: "⚠️ Limited data ({N} sessions, {M} days). Treat as directional, not conclusive."
- Omit benchmarking (insufficient sample for comparison)
- Recommend: "Extend analysis window to 90+ days for reliable benchmarks."

## Error Handling

| Scenario | Action |
|----------|--------|
| Shop ID not found from domain | Try: (1) permanent_domain with LIKE, (2) strip www/subpath, (3) check `raw_salesforce_banff.website__c`. If still not found: ask user "Confirm the exact domain — is it [x].myshopify.com or [x].com?" |
| UAL returns multiple accounts for same domain | Show all matches. Ask: "Which account? I see {N} matches — could be parent/subsidiary." |
| Query returns 0 rows | Check: (1) Is shop_id correct? (2) Is date range appropriate? (3) Does the shop have enough traffic? Report: "No {metric} data found for shop {id} in last 90 days. This shop may be very new, inactive, or on a plan without analytics." |
| BigQuery access denied on specific table | Note which table failed. Suggest alternative: e.g., if `growth_services_prod` denied, try `buyer_activity.storefront_sessions_summary_v3` instead. |
| Session count < 100 for analysis period | Flag: "Low session count ({N}). Data unreliable for statistical comparison." Extend date range to 180 or 365 days automatically. |
| Multiple research types requested but some fail | Report successes normally. For failures: "Could not run {type} analysis: {reason}. Run manually via: {query filename}" |
| User provides shop name (not domain) | Search UAL by name (LIKE match). If multiple: list all and ask. Do NOT assume a match. |
| Benchmark comparison shows merchant is an extreme outlier (e.g., CR 0.01%) | Flag: "This CR is extremely low — possible data quality issue (bot traffic, test shop, or tracking misconfiguration). Verify with `perf-suspicious-traffic.sql` before drawing conclusions." |
| User asks for competitor comparison | "I can only analyze shops where we have Shopify data. For competitor analysis, use `competitive-positioning` skill with external research." |

---


## Platform Reference Data
Load these files for current Shopify platform data before responding:
- `references/integration-patterns.md` — ERP, PIM, OMS, CRM middleware patterns for integration architecture analysis

## Anti-Patterns

- **Don't guess shop IDs** — always resolve from domain or Salesforce
- **Don't run all 49 queries** — match to the research type
- **Don't present raw numbers without context** — always include benchmarks or trends
- **Don't skip the TL;DR** — the executive summary is the most valuable part
