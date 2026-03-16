# BigQuery Tables for Sales Manager Dashboards

## Opportunities
**Table**: `shopify-dw.base.base__salesforce_banff_opportunities`
**Grain**: One row per opportunity
**Key columns**:
- `opportunity_id` — primary key, use for PBR join
- `account_id` — for activity join at account level
- `owner_id` — FK to users table
- `name` — opportunity name
- `stage_name` — current stage
- `is_closed`, `is_won`, `is_deleted` — boolean flags
- `created_at` — timestamp (use `DATE(created_at)` for filtering)
- `close_date` — date type, use for closed opp filtering
- `amount_usd` — Salesforce amount in USD
- `opportunity_type`, `source`, `lead_source`
- `primary_result_reason` — loss reason for closed-lost
- `primary_product_interest`, `region`

**Important**: `is_deleted = FALSE` filter always required. Closed opps filter by `close_date`, open by `created_at`.

## Users
**Table**: `shopify-dw.base.base__salesforce_banff_users`
**Grain**: One row per Salesforce user
**Key columns**:
- `user_id` — primary key, matches `owner_id` in opps
- `name` — full name
- `title`, `is_active`
- `manager_id` — FK to another user (for hierarchy traversal)

## Activity
**Table**: `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity`
**Grain**: One row per activity record
**Key columns**:
- `opportunity_id` — direct match to opp (may be null for account-level activity)
- `account_id` — for broader activity coverage
- `activity_type` — e.g., 'Call', 'Email', 'Meeting'
- `activity_subtype` — e.g., 'Connected Call', 'Email Reply'
- `created_date` — when the activity happened
- `meaningful_activity` — Rev Ops flag (too strict — compute your own tiers)

**Query pattern for aggregation**:
```sql
SELECT
  opportunity_id,
  COUNT(*) as total_acts,
  COUNTIF(activity_subtype = 'Connected Call') as connected_calls,
  COUNTIF(activity_subtype = 'Email Reply') as email_replies,
  COUNTIF(activity_type = 'Meeting') as meetings
FROM `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity`
WHERE opportunity_id IS NOT NULL
GROUP BY opportunity_id
```

Also query account-level activity separately for engagement tier fallback:
```sql
SELECT account_id, COUNT(*) as account_acts
FROM `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity`
WHERE account_id IS NOT NULL
GROUP BY account_id
```

## PBR (Projected Billed Revenue)
**Table**: `sdp-for-analysts-platform.rev_ops_prod.report_revenue_reporting_sprint_billed_revenue_cohort`
**Grain**: One row per opportunity × months_since_close
**Key columns**:
- `opportunity_id` — join key to opps
- `oppty_pbr` — Projected Billed Revenue (use this as the main PBR value)
- `oppty_pbr_at_close` — PBR calculated at time of close
- `oppty_br` — Actual Billed Revenue
- `cumulative_oppty_br` — Running total of actual billed
- `months_since_close` — 0 = at close, 1 = one month later, etc.
- `segment`, `motion` — team segment filters

**Important**: Filter `months_since_close = 0` for at-close PBR. This table only has data for closed-won deals.

## Attainment
**Table**: `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events`
**Grain**: One row per worker × metric
**Key columns**:
- `full_name` — matches SF user name
- `metric` — e.g., "Billed Revenue" (filter on this)
- `quota` — target amount
- `credit` — credit toward quota
- `attainment` — decimal (0.5 = 50%)
- `projected_revenue` — forecasted revenue

## Forecast (Executive)
**Table**: `sdp-for-analysts-platform.rev_ops_prod.RPI_executive_summary_forecast`
**Key columns**:
- `closed_won_projected_billed_revenue_sales_final_forecast` — CW PBR forecast
- `_target` suffix columns — targets

## Access Notes
- `shopify-dw.base.*` — generally accessible
- `sdp-for-analysts-platform.rev_ops_prod.*` — accessible (verified)
- `sdp-prd-commercial.intermediate.*` — **403 access denied**, do not use
