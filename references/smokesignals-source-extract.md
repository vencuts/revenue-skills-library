# Smokesignals — Full Source Extract (2026-03-16)
*Extracted from smokesignals.quick.shopify.io Vite bundle (281KB) via Quick MCP*

## Data Sources Confirmed
1. `shopify-dw.sales.sales_accounts_v1` — Book of Business (territory-filtered)
2. `shopify-dw.sales.sales_opportunities` — Opp data (closed-lost analysis)  
3. `shopify-dw.sales.shop_to_sales_account_mapping` — Shop→Account bridge
4. `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` — Campaign engagement
5. `shopify-dw.accounts_and_administration.shop_subscription_milestones` — Trial events
6. SEC EDGAR (`efts.sec.gov/LATEST/search`) — 10-K, 10-Q, 8-K filings
7. News (Google News RSS, Bing News RSS, NewsAPI) — Company news
8. `quick.db` — User settings, signal reports (persisted per user)
9. Shopify AI Proxy (`claude-opus-4-6`) — Signal analysis + scoring

## Key SQL: Load Book of Business
```sql
SELECT
  a.account_id, a.name, a.industry,
  a.annual_total_revenue_usd AS revenue,
  a.domain_clean AS website,
  a.territory_name AS territory,
  a.account_grade AS grade,
  a.ecomm_platform AS platform,
  a.account_priority_d2c AS priority,
  a.sales_lifecycle_stage, a.plus_status, a.account_type,
  a.billing_country, a.billing_state, a.number_of_employees, a.account_url
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.territory_name IN ({territories})
  AND a.account_id IS NOT NULL
ORDER BY a.annual_total_revenue_usd DESC NULLS LAST
LIMIT 5000
```

## Key SQL: Campaign Engagements
```sql
SELECT
  sam.salesforce_account_id AS account_id,
  t.campaign_name, t.campaign_type_category, t.campaign_member_status,
  FORMAT_TIMESTAMP('%Y-%m-%d', t.touchpoint_timestamp) AS event_date,
  t.is_interaction_touchpoint
FROM `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` t
INNER JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam
  ON t.shop_id = sam.shop_id
WHERE sam.salesforce_account_id IN ({account_ids})
  AND t.campaign_type_category IN ('Event', 'Webinar')
  AND t.touchpoint_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
```

## Key SQL: Subscription Milestones
```sql
SELECT
  sam.salesforce_account_id AS account_id,
  ms.event_type,
  FORMAT_TIMESTAMP('%Y-%m-%d', ms.event_at) AS event_date
FROM `shopify-dw.accounts_and_administration.shop_subscription_milestones` ms
INNER JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam ON ms.shop_id = sam.shop_id
WHERE sam.salesforce_account_id IN ({account_ids})
  AND ms.event_type IN ('free_trial_started', 'paid_trial_shop', 'first_paid_trial_subscription_started')
  AND ms.event_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
```

## Signal Scoring Architecture
- **Tiers**: tier1 (high points), tier2 (medium), tier3 (low)
- **Urgency**: hot / warm / developing / watch (based on total score)
- **Signal types**: opportunity, engagement, filing, news, timing, platform
- **RANT Assessment**: Relevance, Authority, Need, Timing (per account)
- **Features**: stackAnalysis (narrative connecting signals), hypotheses, recommendedContacts, followUpTriggers, talkingPoints
- **AI model**: claude-opus-4-6 via Shopify AI proxy

## Territory Example
Jackson Waggoner's territories: `AMER_Large_All_Consumer_A_D2CRetail_05`, `AMER_Large_All_Lifestyle_A_D2CRetail_08`

## What We Already Had (from prior analysis)
Our `references/smokesignals-signal-scoring.md` had the 17-signal tiered scoring model. This new extract adds:
- Complete SQL queries (now we can replicate the data pipeline)
- RANT assessment framework
- Stack analysis + hypotheses generation
- Full account data model (fields from sales_accounts_v1)
- Campaign + milestone integration patterns
