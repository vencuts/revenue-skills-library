# BQ Table Quick Reference — Revenue Skills

Most-used tables by domain. All names are fully-qualified (`project.dataset.table`).

## Pipeline & Opportunities

| Table | What it has | Key columns |
|-------|------------|-------------|
| `shopify-dw.rpt_salesforce_banff.opportunity` | All Salesforce opportunities | `opportunity_id`, `account_id`, `amount`, `stage_name`, `close_date`, `owner_id` |
| `shopify-dw.rpt_salesforce_banff.account` | Account master | `account_id`, `name`, `industry`, `billing_country` |
| `shopify-dw.rpt_salesforce_banff.user` | SF user records | `user_id`, `name`, `email`, `manager_id` |
| `shopify-dw.mart_revenue_data.sales_opportunity_reporting_metrics` | Pre-aggregated opp metrics | PBR, stage dates, segment, rep info — preferred for dashboards |
| `shopify-dw.mart_revenue_data.sales_user_roles` | Rep roles + segments | `email`, `segment`, `role`, `manager_email` — USE THIS for segment, not market_segment |

## Calls & Transcripts

| Table | What it has | Key columns |
|-------|------------|-------------|
| `shopify-dw.mart_revenue_data.sales_calls` | All call records (Google Meet + SalesLoft + MS Teams unified) | `call_id`, `opportunity_id`, `account_id`, `transcript`, `duration_seconds`, `attendees` |

**Gotcha:** Before Mar 2026, only SalesLoft calls were in the table. Google Meet transcripts (from Gemini) are now included — they appear in 54% of deals and were previously invisible.

**3-tier matching for calls to opps:**
1. Direct: `opportunity_id` is set on the call
2. Account-scoped: match by `account_id` + date window (opp created → opp closed ± 30 days)
3. Fuzzy: match by attendee email domain + account name similarity

## Emails & Activity

| Table | What it has | Key columns |
|-------|------------|-------------|
| `shopify-dw.mart_revenue_data.sales_emails` | All email records (SalesLoft + SF + Mozart unified) | `email_id`, `opportunity_id`, `account_id`, `subject`, `body`, `sent_at`, `is_inbound` |

**Gotcha:** For reply rate calculations, use `replied_to_email_id IS NOT NULL` (precise), NOT `is_inbound = true` (inflated by 9 percentage points — counts forwarded emails as replies).

## Quotas & Attainment

| Table | What it has | Key columns |
|-------|------------|-------------|
| `shopify-dw.people.incentive_compensation_monthly_quotas` | Individual rep quota targets (2026+) | `worker_id`, `month`, `metric` (billed_revenue/NRR/SALs/solution_activations/total_ads_spend), `amount` |
| `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events` | Attainment + quota (pre-joined) | `worker_id`, `metric`, `quota`, `credit`, `attainment` |

**Formula for pipeline coverage:**
```sql
SAFE_DIVIDE(open_pipeline, (quota_target - closed_won_qtd))
```
This gives "remaining gap coverage" — how much open pipe covers what's still needed.

## SE Engagement

| Source | What it has | How to access |
|--------|------------|---------------|
| SE-NTRAL (`se-ntral.quick.shopify.io`) | Technical assessments, PMF scores, MEDDPICC scores, discovery notes, 18K+ documents | Quick API — search by merchant name or opportunity ID |

## Competitive & Market Data

| Table | What it has | Key columns |
|-------|------------|-------------|
| `sdp-prd-growth-labs.storeleads.current_storeleads` | Platform detection, tech stacks, migration signals | `domain`, `platform`, `last_platform_change_at`, `estimated_revenue`, `tech_stack` |

## Common SQL Patterns

### PBR by segment (correct way)
```sql
SELECT
  sur.segment,
  SUM(o.amount) AS total_pbr
FROM `shopify-dw.rpt_salesforce_banff.opportunity` o
JOIN `shopify-dw.mart_revenue_data.sales_user_roles` sur
  ON o.owner_id = sur.user_id
WHERE o.close_date >= DATE_TRUNC(CURRENT_DATE()-1, QUARTER)
  AND o.is_won = true
GROUP BY 1
```

### YoY comparison (correct alignment)
```sql
-- Use CURRENT_DATE()-1 to avoid incomplete today
-- Align CY and PY windows to same day-of-quarter
WHERE close_date BETWEEN
  DATE_TRUNC(CURRENT_DATE()-1, QUARTER)
  AND CURRENT_DATE()-1
```

### Safe division
```sql
SAFE_DIVIDE(numerator, denominator) -- returns NULL instead of error
```
