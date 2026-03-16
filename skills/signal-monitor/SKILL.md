---
name: signal-monitor
description: Monitor accounts for buying signals from SEC filings, news, Shopify engagement data, and closed-lost opportunities. Use when asked to "check signals for [account]", "any news on [company]", "buying signals", "signal scan", "what's happening with my accounts", "RANT assessment", "who should I reach out to", "outreach triggers", or when preparing for territory reviews. Works for SDRs, BDRs, AEs doing outbound, and sales managers reviewing territory health.
---

# Signal Monitor

Scan accounts for buying signals across multiple data sources, score them by urgency, and generate outreach recommendations. Combines SEC filings, company news, Shopify first-party engagement data, and closed-lost history into a prioritized signal feed.

**Source**: Patterns extracted from smokesignals.quick.shopify.io (Jackson Waggoner, AE). Full architecture in `references/smokesignals-source-extract.md` and `references/smokesignals-signal-scoring.md`.

## Required Tools

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` / `agent-data` | Pull account data, campaign engagements, subscription milestones, closed-lost opps from `sales.*` tables | Cannot run signal scan. Tell user: "BQ access required for first-party signals." |
| `perplexity_search` / `web_search` | Company news, press releases, funding announcements | Skip news signals. Score from first-party data only. Flag: "External signals unavailable — scoring from Shopify data only." |
| `web_fetch` | SEC EDGAR filing search (`efts.sec.gov/LATEST/search-index`) | Skip filing signals. Note: "SEC data unavailable — public company signals excluded." |
| `slack_search` | Check recent mentions of the account in sales channels | Skip internal context. Note: "No Slack context — checking data only." |

## Workflow

### Step 0: Data Integrity Check

Run `data-integrity-check` on the account/territory first. If confidence is LOW, warn: "Account data may be unreliable — signals could be based on stale or incomplete records."

### Step 1: Identify Target Accounts

**Has the user specified accounts?**
- **Yes, by name** → Look up in UAL to get `account_id`. If multiple matches, ask which one.
- **Yes, by territory** → Query book of business:

```sql
SELECT
  a.account_id, a.name, a.industry,
  a.annual_total_revenue_usd AS revenue,
  a.domain_clean AS website,
  a.territory_name AS territory,
  a.account_grade AS grade,
  a.ecomm_platform AS platform,
  a.account_priority_d2c AS priority,
  a.sales_lifecycle_stage, a.plus_status, a.account_type
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.territory_name = @territory_name
  AND a.account_id IS NOT NULL
ORDER BY a.annual_total_revenue_usd DESC NULLS LAST
LIMIT 200
```
**Result interpretation**: If 0 rows → territory code is wrong. Ask user to verify. If < 10 → small territory, expect fewer signals. If > 200 → large territory, recommend filtering by priority first.

- **No** → Ask: "Which accounts or territory should I scan?"

### Step 2: Gather First-Party Signals (BQ)

Run these queries in parallel for the target account(s):

**Campaign/Event Engagement** (via shop→account bridge):
```sql
SELECT
  sam.salesforce_account_id AS account_id,
  t.campaign_name, t.campaign_type_category,
  t.campaign_member_status,
  FORMAT_TIMESTAMP('%Y-%m-%d', t.touchpoint_timestamp) AS event_date,
  t.is_interaction_touchpoint
FROM `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` t
INNER JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam
  ON t.shop_id = sam.shop_id
WHERE sam.salesforce_account_id = @account_id
  AND t.campaign_type_category IN ('Event', 'Webinar')
  AND t.touchpoint_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
ORDER BY t.touchpoint_timestamp DESC
```
**Result interpretation**: Rows with `is_interaction_touchpoint = true` = attended (25 pts). Rows without = registered only (15 pts). 0 rows = no Shopify engagement.

**Subscription Milestones** (trial signals):
```sql
SELECT
  sam.salesforce_account_id AS account_id,
  ms.event_type,
  FORMAT_TIMESTAMP('%Y-%m-%d', ms.event_at) AS event_date
FROM `shopify-dw.accounts_and_administration.shop_subscription_milestones` ms
INNER JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam
  ON ms.shop_id = sam.shop_id
WHERE sam.salesforce_account_id = @account_id
  AND ms.event_type IN ('free_trial_started', 'paid_trial_shop', 'first_paid_trial_subscription_started')
  AND ms.event_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
ORDER BY ms.event_at DESC
```
**Result interpretation**: `paid_trial_shop` = 50 pts (highest urgency). `free_trial_started` = 40 pts. `first_paid_trial_subscription_started` = 35 pts. 0 rows = no trial activity.

**Closed-Lost Opportunities**:
```sql
SELECT opportunity_id, name, close_date, amount_usd,
  primary_result_reason, secondary_result_reason, reason_details,
  compelling_event, primary_product_interest
FROM `shopify-dw.sales.sales_opportunities`
WHERE account_id = @account_id
  AND current_stage_name = 'Closed Lost'
  AND close_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 18 MONTH)
ORDER BY close_date DESC
```
**Result interpretation**: Any closed-lost opp = 60 pts (highest signal). The `primary_result_reason` tells you WHY they didn't buy — address this directly in outreach. Multiple closed-lost = persistent interest + persistent blocker.

**Open Opportunities** (exclude from scoring, show as context):
```sql
SELECT opportunity_id, name, current_stage_name, amount_usd, close_date
FROM `shopify-dw.sales.sales_opportunities`
WHERE account_id = @account_id
  AND current_stage_name NOT IN ('Closed Won', 'Closed Lost')
```
**Do NOT score open opps** — they're already being worked. Show as greyed context: "{N} open, {M} closed lost"

### Step 3: Gather External Signals

**SEC EDGAR** (public companies only — skip if domain doesn't match a public filing entity):
- Search `https://efts.sec.gov/LATEST/search-index?q={company_name}&dateRange=custom&startdt={1_year_ago}&enddt={today}&forms=10-K,10-Q,8-K`
- 10-K = annual report (25 pts if ecommerce/digital mentioned in strategy)
- 10-Q = quarterly (20 pts if relevant mentions)
- 8-K = material events (35 pts — active vendor evaluation, M&A, exec changes)

**News** (fallback chain — try in order, stop on first success):
1. `perplexity_search` — best synthesis, handles company name disambiguation
2. `web_search` — Google results, wider coverage
3. If neither available: skip news signals entirely

Score news: Funding/IPO = 35 pts. Exec hire = 40 pts. Product launch = 20 pts. M&A = 20 pts. Generic press = 15 pts.

### Step 4: Score & Classify

**Apply the tiered scoring** from `references/smokesignals-signal-scoring.md`:
- Sum all signal points
- Classify urgency: **Hot** (80+ pts), **Warm** (50-79), **Developing** (25-49), **Watch** (<25)

**RANT Assessment** (for each account):
- **R — Relevance**: Does their business model fit Shopify? Is their platform a known migration source?
- **A — Authority**: Can we identify decision-makers? Do we have contacts at the right level?
- **N — Need**: Is there a demonstrable business need (platform pain, growth constraint, competitive pressure)?
- **T — Timing**: Is there a time-bound trigger (contract expiry, trial, funding, exec change)?

RANT is complementary to MEDDPICC. RANT = "should I reach out?" (pre-qualification). MEDDPICC = "is this a real deal?" (post-engagement qualification via `opp-compliance-checker`).

### Step 5: Generate Stack Analysis

Connect the individual signals into a narrative:
- What's the **buying story**? (Multiple signals pointing to the same conclusion)
- What are the **business hypotheses**? (What we think is happening at this company)
- Who should we **contact** and via what channel?
- What are the **follow-up triggers**? (Events that would change the urgency)

## Output Format

```
🔔 SIGNAL REPORT: {company_name}
Urgency: {🔴 Hot / 🟠 Warm / 🟡 Developing / ⚪ Watch} ({total_points} pts)

📊 RANT Assessment
  R (Relevance): {assessment}
  A (Authority):  {assessment}
  N (Need):       {assessment}
  T (Timing):     {assessment}

🔗 Signal Stack Analysis
  {2-3 sentence narrative connecting the signals into a buying story}

💡 Business Hypotheses
  → {hypothesis 1}
  → {hypothesis 2}

📡 Signals ({count} detected)
  TIER 1 — Immediate
    {signal} ({points} pts) — {date} — {description}
  TIER 2 — Priority
    {signal} ({points} pts) — {date} — {description}
  TIER 3 — Watch
    {signal} ({points} pts) — {date} — {description}

📋 Recommended Approach
  {suggested outreach strategy based on signals}

👤 Recommended Contacts
  {title} — via {channel} — {reason}

⏰ Follow-Up Triggers
  • {trigger that would change urgency}
```

**Conditional sections:**
- If urgency is Watch and no signals found → short output: "No actionable signals. Limited public data for this account."
- If there are open opps → add greyed "Active Pipeline" section (excluded from scoring)
- If closed-lost exists → always include loss reason prominently (it's the #1 re-engagement angle)

## Error Handling

| Scenario | Action |
|----------|--------|
| Account not found in UAL | Check spelling, try domain search. If still nothing: "Account not in Salesforce. Use `prospect-researcher` for net-new accounts." |
| `shop_to_sales_account_mapping` returns no rows | Account has no Shopify shops linked. First-party signals (trials, events) will be empty. Score from external sources only. |
| EDGAR returns no filings | Company is likely private. Skip SEC signals. Note: "Private company — no SEC filings available." |
| BQ query returns permission error on `sales.*` tables | Fall back to `base__salesforce_banff_*` tables (same data, fewer enriched fields). Note the fallback. |
| All external sources fail | Score from first-party BQ data only. Flag: "External signals unavailable — scoring from Shopify engagement data only. Confidence: MEDIUM." |
| User asks about a company that's already a Shopify customer | Do NOT run acquisition signals. Check `sales_lifecycle_stage` and `plus_status`. Redirect: "This account is already on Shopify ({lifecycle stage}). For expansion signals, check `account-research` instead." |
| Territory scan returns 200+ accounts | Too many to scan individually. Recommend: "Filter to High priority accounts first, or pick specific accounts." |
| Signal score is 0 for a high-priority account | Report honestly: "No signals detected. This could mean limited public presence, or the account hasn't engaged with Shopify recently. Consider cold outreach via `outbound-cadence`." |

## Scope & Boundaries

- **Do NOT** use this skill for existing Shopify merchants — use `account-research` for customer health
- **Do NOT** score open opportunities — they're already being worked
- **Do NOT** treat news articles as confirmed facts — flag as "unverified external signal"
- **Do NOT** make SEC filing claims without linking to the actual filing
- **Do NOT** recommend outreach to accounts with active open opportunities without flagging the existing pipeline
- **This skill is NOT an outreach writer** — use `outbound-cadence` to generate emails after identifying targets here
