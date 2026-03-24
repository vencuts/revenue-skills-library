---
name: csm-portfolio-triage
description: Prioritize a CSM's account portfolio by health, risk, and engagement — answering "what needs my attention today?" Pulls portfolio data from BigQuery, scores accounts across 6 health dimensions, classifies journey stages, flags risk triggers and engagement gaps, and delivers a prioritized action list. Use when asked to "triage my portfolio", "which accounts need attention", "what should I focus on today", "prioritize my book", "portfolio health check", "show at-risk accounts", "account priority list", or "morning portfolio review". Built for CSMs managing 20-50 accounts; also works for Leads reviewing a team member's book.
---

# CSM Portfolio Triage

Prioritize a CSM's account portfolio by health, risk, and engagement — the 9am question: **"Which of my accounts need attention today, and why?"**

You are NOT a deal prioritizer — this skill triages post-sales **portfolio accounts** by health score, risk flags, and engagement recency, NOT by deal stage or close date (use `deal-prioritization` for pipeline). You are NOT a revenue forecaster — do NOT project NRR or quota attainment (use `nrr-pacing`). You are NOT a risk mitigation planner — flag at-risk accounts but do NOT generate mitigation action plans (use `risk-mitigation-playbook`).

**[INTERNAL-ONLY]** — do not share output externally.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` / `agent-data` | Portfolio accounts, health scores, product adoption, activity, risk level, GMV, revenue, SP penetration | **Fallback chain**: (1) Try `revenue-mcp` with this Salesforce query: `SELECT Id, Name, Risk_Level__c, Merchant_Success_Manager__c FROM Account WHERE Merchant_Success_Manager_Email__c = '{csm_email}'` — gives account names + risk levels (enough for Gate 1-2 of the decision tree). (2) If revenue-mcp also unavailable, ask user to export from CS Compass (Overview → top-right Export button → CSV) or paste account names. (3) If user provides raw data, run manual triage per Step 1b. Each fallback level loses scoring dimensions but still produces a usable prioritization — see fallback coverage matrix below. |
| `vault_search` | Look up CSM name/email, team structure, segment assignment | Ask user directly: "What's the CSM email and segment?" Minor impact — proceed without. |
| `slack_search` | Recent internal mentions of flagged accounts for additional context | Skip Slack context. Note: "No Slack context — check account channels manually for flagged accounts." |

**Graceful degradation priority**: Full BQ query → revenue-mcp Salesforce fallback → user-provided CS Compass export → manual triage from user-pasted account list. Always produce SOMETHING — even a basic prioritization of 5 accounts the user lists manually is valuable. The only hard failure is zero account data from any source.

**Timeout handling**: If BQ query does not return within 30 seconds, abort and try revenue-mcp fallback query. If that also fails, ask: "BQ is slow — can you share your account list? Options: (a) CS Compass CSV export, (b) paste account names with GMV and last activity, or (c) your top 5–10 accounts you're worried about."

**Fallback coverage**: Full BQ = all gates. revenue-mcp (SF only) = Gates 1-2 only (risk-focused triage). CS Compass CSV = near-full (note CSV freshness). User-provided list = partial (see Step 1b).

---

## Key Domain Vocabulary

- **NRR** — Net Revenue Retention. The metric CS is measured on.
- **Foundation Stack** — Shopify Payments + Shop Pay + Shop Pay Installments. The baseline product adoption every Plus merchant should have.
- **SP Penetration** — Shopify Payments processing volume as a share of total GMV. Target: ≥50%.
- **Journey Stage** — Where the account is in the CS lifecycle: Risk, Onboarding, Adoption, Growth, Protect, or Renewals.
- **Book of Business (BoB)** — A CSM's assigned account portfolio.
- **Engagement Compliance** — Whether the CSM has contacted the account within the target frequency for its segment and priority tier.
- **Segment** — Team structure: Unicorn, Mid-Market Scaled, Mid-Market Assigned, Large Accounts. Each has different engagement targets.
- **Priority Tier** — Derived from segment percentile ranking: High Priority (Invest), Medium Priority (Maintain), Low Priority (Steady State).
- **Weighted Percentile Rank** — Account's relative position within its segment based on a composite score (GMV weight × risk × adoption).
- **RHS Tier** — Risk-Health Score tier from CS Compass. Values: `Healthy` (score 15+, engagement 4+), `Atrophying` (score 7-14 or engagement dropping), `At Risk` (score <7 or engagement <2). When RHS tier conflicts with risk_category (e.g., CRITICAL risk but Healthy RHS), **risk_category wins for triage prioritization** — RHS measures trajectory while risk_category captures acute flags. Note the conflict in the output: "⚠️ RHS shows Healthy but risk flags active — investigate whether flags are stale or RHS hasn't updated."
- **RHS Score** — Composite 0-25 scale combining engagement, revenue trajectory, and product adoption. Higher = healthier. The `rhs_engagement` sub-score (0-12 scale) counts qualifying touchpoints in the last 90 days.
- **Risk Score** — Numeric score (0-29 scale) computed from 3 pillars: Financial (pillar 2: Negative YoY, QoQ Decline, Low SP Pen, Declining SP), Operational (pillar 3: Major Outage, Recurring Incidents, Silent Dissatisfaction, Support Spike), Relationship (pillar 4: Escalated Tickets, SF High Risk, Low Engagement, No Exec Contacts, Exec Disengagement). Score ≥18 = CRITICAL, ≥12 = HIGH, ≥6 = MODERATE, <6 = LOW.
- **Risk Flags** — The specific conditions triggering risk. Full taxonomy (21 flags):
  - **Auto-critical (any one = CRITICAL):** TERMINATION, PAYOUT FREEZE, SP REJECTION, FRAUD, AUP OFFENSE, CHECKOUT INCIDENT, IMMINENT CHURN
  - **Financial (pillar 2):** Negative YoY, QoQ Decline, Low SP Pen, Declining SP
  - **Operational (pillar 3):** Major Outage, Recurring Incidents, Silent Dissatisfaction, Support Spike
  - **Relationship (pillar 4):** Escalated Tickets, SF High Risk, Low Engagement, No Exec Contacts, Exec Disengagement
- **Mitigation Status** — Accounts flagged at-risk may already have an active mitigation action in CS Compass. Statuses: `draft` (CSM drafting), `pending_lead` (awaiting lead approval), `pending_director` (awaiting director approval), `approved` (in execution), `completed` (outcome tracked). Check before recommending new actions.

---

## Workflow

### Step 0: Identify the CSM

Determine whose portfolio to triage:

- **Has CSM email?** → Use directly in queries
- **Has CSM name?** → Look up via `vault_search` or ask for email
- **No CSM specified?** → Ask: "Whose portfolio should I triage? Give me the CSM name or email."
- **User IS the CSM?** → Ask for their Shopify email address

Also determine the CSM's **segment** if possible (Unicorn, Mid-Market Scaled, Mid-Market Assigned, Large Accounts). This affects engagement targets and peer comparison. If unknown, the query will return it.

### Step 1: Pull Portfolio Data

Run the portfolio query scoped to the target CSM. This single query returns account-level data with health scores, product adoption, activity, and risk indicators.

```sql
WITH target_accounts AS (
    SELECT
      sa.account_id,
      sa.organization_id,
      sa.merchant_success_manager AS csm_name,
      sa.merchant_success_manager_email AS csm_email,
      su.manager_name AS cs_lead,
      su.manager_email AS lead_email,
      CASE
        WHEN su.manager_name = 'Megan Schmidling' THEN 'Unicorn'
        WHEN su.manager_name IN ('Nikole Gabriel-Brooks', 'Aiko Lista', 'Arnaud Bonnet') THEN 'Mid-Market Scaled'
        WHEN su.manager_name IN ('Jared Frazer', 'Kasia Mycek') THEN 'Mid-Market Assigned'
        WHEN su.manager_name IN ('Niresan Seevaratnam', 'Tyler Cuddihey', 'Amy Franklin') THEN 'Large Accounts'
        ELSE 'N/A'
      END AS segment,
      sa.name AS account_name,
      sa.risk_level AS sf_risk_level,
      sa.industry,
      sa.region,
      sa.service_model
    FROM `shopify-dw.sales.sales_accounts` AS sa
    LEFT JOIN `shopify-dw.sales.sales_users` AS su
      ON sa.merchant_success_manager_id = su.user_id
    WHERE su.is_active = TRUE
      AND LOWER(sa.merchant_success_manager_email) = LOWER(@csm_email)
),

target_shop_ids AS (
  SELECT DISTINCT map.shop_id, map.account_id
  FROM `shopify-dw.mart_revenue_data.revenue_shop_salesforce_summary` AS map
  INNER JOIN target_accounts AS t ON map.account_id = t.account_id
),

account_metrics AS (
  SELECT
    copilot.account_id,
    copilot.gmv_usd_l365d,
    copilot.revenue_l12m,
    SAFE_DIVIDE(copilot.revenue_l12m, copilot.gmv_usd_l365d) AS take_rate,
    copilot.gmv_growth_yearly AS gmv_growth_yoy,
    copilot.gmv_growth_quarterly AS gmv_growth_qoq,
    copilot.banff_risk_level
  FROM `sdp-prd-commercial.mart.copilot_account_attributes` AS copilot
  INNER JOIN target_accounts AS t ON copilot.account_id = t.account_id
),

product_adoption AS (
  SELECT
    csa.account_id,
    MAX(CAST(COALESCE(csa.shopify_payments.adopted_shopify_payments, FALSE) AS INT64)) AS has_payments,
    MAX(CAST(COALESCE(csa.shop_pay.adopted_shop_pay, FALSE) AS INT64)) AS has_shop_pay,
    MAX(CAST(COALESCE(csa.plus.is_shopify_flow_currently_installed, FALSE) AS INT64)) AS has_flow,
    MAX(CAST(COALESCE(csa.plus.is_shopify_audiences_currently_installed, FALSE) AS INT64)) AS has_audiences,
    SUM(COALESCE(csa.retail.retail_gmv_usd_l365d, 0)) AS retail_gmv,
    SUM(COALESCE(csa.b2b.b2b_gmv_l365d, 0)) AS b2b_gmv,
    (MAX(CAST(COALESCE(csa.shopify_payments.adopted_shopify_payments, FALSE) AS INT64)) +
     MAX(CAST(COALESCE(csa.shop_pay.adopted_shop_pay, FALSE) AS INT64)) +
     MAX(CAST(COALESCE(csa.plus.is_shopify_flow_currently_installed, FALSE) AS INT64)) +
     MAX(CAST(COALESCE(csa.plus.is_shopify_audiences_currently_installed, FALSE) AS INT64)) +
     CASE WHEN SUM(COALESCE(csa.retail.retail_gmv_usd_l365d, 0)) > 0 THEN 1 ELSE 0 END +
     CASE WHEN SUM(COALESCE(csa.b2b.b2b_gmv_l365d, 0)) > 0 THEN 1 ELSE 0 END) AS products_adopted
  FROM `sdp-prd-commercial.mart.copilot_shop_attributes` AS csa
  INNER JOIN target_shop_ids AS t ON csa.shop_id = t.shop_id
  GROUP BY csa.account_id
),

sp_penetration AS (
  SELECT
    t.account_id,
    COALESCE(SAFE_DIVIDE(
      SUM(CASE WHEN DATE(sp.date) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) THEN sp.gpv_usd END),
      SUM(CASE WHEN DATE(sp.date) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) THEN sp.gmv_usd END)
    ), 0) AS sp_penetration_l12m
  FROM target_shop_ids AS t
  LEFT JOIN `shopify-dw.mart_payments.shopify_payments_shop_monthly_kpis` AS sp
    ON t.shop_id = sp.shop_id
  WHERE DATE(sp.date) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY t.account_id
),

activity AS (
  SELECT
    t.account_id,
    DATE(MAX(act.date_of_activity)) AS last_activity_date,
    DATE_DIFF(CURRENT_DATE(), DATE(MAX(act.date_of_activity)), DAY) AS days_since_activity,
    COUNT(DISTINCT CONCAT(act.account_id, '_', CAST(act.date_of_activity AS STRING))) AS activity_count_l90
  FROM `sdp-for-analysts-platform.rev_ops_prod.report_post_sales_dashboard_activities` AS act
  INNER JOIN `shopify-dw.raw_salesforce_banff.event` AS ev ON act.activity_id = ev.Id
  INNER JOIN target_accounts AS t ON act.account_id = t.account_id
  WHERE (act.activity_type LIKE '%Meeting%' OR act.activity_type LIKE '%Call%' OR LOWER(act.activity_type) = 'in-person meeting')
    AND DATE(act.date_of_activity) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND DATE(act.date_of_activity) <= CURRENT_DATE()
    AND (ev.Meeting_No_Show__c IS NULL OR ev.Meeting_No_Show__c = FALSE)
    AND (ev.Status__c IS NULL OR ev.Status__c NOT IN ('Cancelled'))
    AND (ev.IsDeleted IS NULL OR ev.IsDeleted = FALSE)
  GROUP BY t.account_id
),

health_scores AS (
  SELECT
    t.account_id,
    CASE WHEN am.gmv_growth_yoy < -0.15 THEN 0 WHEN am.gmv_growth_yoy < -0.05 THEN 0.15
         WHEN am.gmv_growth_yoy < 0 THEN 0.30 WHEN am.gmv_growth_yoy < 0.05 THEN 0.60
         WHEN am.gmv_growth_yoy < 0.10 THEN 0.80 ELSE 1 END AS gmv_score,
    CASE WHEN am.banff_risk_level = 'Low' THEN 1 WHEN am.banff_risk_level = 'Medium' THEN 0.5 ELSE 0 END AS risk_score,
    CASE WHEN sp.sp_penetration_l12m >= 0.80 THEN 1.0 WHEN sp.sp_penetration_l12m >= 0.60 THEN 0.75
         WHEN sp.sp_penetration_l12m >= 0.40 THEN 0.50 WHEN sp.sp_penetration_l12m >= 0.20 THEN 0.30 ELSE 0.15 END AS sp_score,
    COALESCE(pa.products_adopted / 6.0, 0) AS product_score
  FROM target_accounts AS t
  LEFT JOIN account_metrics AS am ON t.account_id = am.account_id
  LEFT JOIN sp_penetration AS sp ON t.account_id = sp.account_id
  LEFT JOIN product_adoption AS pa ON t.account_id = pa.account_id
)

SELECT
  t.account_id, t.account_name, t.csm_name, t.csm_email, t.cs_lead AS lead_name,
  t.segment, LEFT(t.region, 4) AS region, t.industry,
  am.gmv_usd_l365d AS gmv_l365d, am.revenue_l12m, am.take_rate,
  am.gmv_growth_yoy, am.gmv_growth_qoq, am.banff_risk_level AS risk_level,
  COALESCE(pa.has_payments, 0) AS has_payments, COALESCE(pa.has_shop_pay, 0) AS has_shop_pay,
  COALESCE(pa.has_flow, 0) AS has_flow, COALESCE(pa.has_audiences, 0) AS has_audiences,
  COALESCE(pa.products_adopted, 0) AS products_adopted,
  CASE
    WHEN COALESCE(pa.has_payments, 0) = 1 AND COALESCE(pa.has_shop_pay, 0) = 1
         AND COALESCE(sp.sp_penetration_l12m, 0) >= 0.5 THEN 'Strong'
    WHEN COALESCE(pa.has_payments, 0) = 1 AND COALESCE(pa.has_shop_pay, 0) = 1 THEN 'Building'
    ELSE 'At Risk'
  END AS foundation_status,
  COALESCE(sp.sp_penetration_l12m, 0) AS sp_penetration,
  act.last_activity_date,
  COALESCE(act.days_since_activity, 999) AS days_since_activity,
  COALESCE(act.activity_count_l90, 0) AS activity_count_l90,
  ROUND((
    (COALESCE(hs.gmv_score, 0.5) * 0.24) + (COALESCE(hs.risk_score, 0.5) * 0.13) +
    (COALESCE(hs.sp_score, 0.5) * 0.12) + (COALESCE(hs.product_score, 0.5) * 0.13) + 0.38
  ) * 100, 1) AS health_score,
  CASE
    WHEN am.banff_risk_level IN ('High', 'Critical') THEN 'Risk'
    WHEN COALESCE(pa.has_payments, 0) = 0 OR COALESCE(pa.has_shop_pay, 0) = 0 THEN 'Foundations'
    WHEN am.gmv_growth_yoy >= 0.10 THEN 'Growth'
    ELSE 'Protect'
  END AS journey_stage
FROM target_accounts AS t
LEFT JOIN account_metrics AS am ON t.account_id = am.account_id
LEFT JOIN product_adoption AS pa ON t.account_id = pa.account_id
LEFT JOIN sp_penetration AS sp ON t.account_id = sp.account_id
LEFT JOIN activity AS act ON t.account_id = act.account_id
LEFT JOIN health_scores AS hs ON t.account_id = hs.account_id
ORDER BY am.gmv_usd_l365d DESC
```

**Query interpretation — what the results mean:**

| Result Pattern | What It Means | What To Do |
|----------------|---------------|------------|
| Returns **0 rows** | CSM email doesn't match any active account assignments in `sales_accounts`. Likely: misspelled email, CSM is inactive/on leave, or recently reassigned. | Try fuzzy match: `LIKE '%lastname%'` on `merchant_success_manager_email`. If still 0, ask user to verify their email or check with their lead. |
| **1-15 rows** returned | Small book — typical for Large Accounts segment. Show full detail for every account. | Use the full output template with per-account detail for all tiers including 🟢 Healthy. |
| **16-50 rows** returned | Standard CSM portfolio. Normal for Mid-Market. | Standard output: full detail for 🔴/🟡, summary table for 🟢. |
| **50+ rows** returned | Either a Lead's full team was queried, or CSM has interim coverage of another book. | Confirm: "Found [N] accounts — should I triage all of them, or filter to a specific segment or priority tier?" |
| **segment = 'N/A'** for all accounts | CSM's manager isn't in the CS Leads list (Aiko Lista, Nikole Gabriel-Brooks, Arnaud Bonnet, Jared Frazer, Amy Franklin, Tyler Cuddihey, Kasia Mycek, Niresan Seevaratnam, Megan Schmidling). CSM may be under a new or interim lead. | Proceed with triage using Mid-Market Scaled engagement targets as default. Note: "⚠️ Segment unresolved — using default engagement targets. Verify team assignment with your lead." |
| **days_since_activity = 999** on most/all accounts | Likely an activities table data issue, NOT genuinely 0 engagement across the entire book. | If >80% of accounts show 999: "⚠️ Activity data appears incomplete — the activities table may be stale. Cross-check recent meetings in your calendar or Salesforce." If only 1-3 accounts show 999, those are genuinely disengaged — flag them. |
| **gmv_l365d is NULL** on an account | Account exists in SF but has no matching copilot_account_attributes. Typical for very new accounts (<30 days) or accounts not yet synced to the copilot mart. | Do NOT exclude from triage. Show as: "GMV: Pending (new account)" and classify as 🟡 Monitor with reason "Incomplete financial data — verify in Salesforce." |
| **health_score is NULL** | One or more scoring inputs were NULL, causing the weighted calculation to produce NULL. | Display as "Health: N/A" and list which inputs were missing. Move to 🟡 Monitor. |
| **risk_level = 'Imminent Churn'** | Salesforce risk field set to highest severity by account team. Requires immediate escalation. | Auto-promote to top of 🔴 Act Now. Add: "🚨 IMMINENT CHURN — escalate to lead immediately." |
| **foundation_status = 'At Risk'** but **health_score > 70** | Account is financially healthy but missing core products (Payments or Shop Pay). Common with large merchants who process payments externally. | Flag in 🟡 Monitor: "Foundation gap despite strong health — confirm if external payment processing is intentional or an adoption opportunity." |
| **gmv_growth_yoy > 0.20** but **days_since_activity > 60** | Fast-growing account with no CSM engagement. Either the account is self-serve successful, or the CSM is missing an opportunity. | Flag in 🟡 Monitor: "High-growth account with engagement gap — is this self-serve success or a missed touchpoint?" |

### Step 1b: Fallback — Manual Triage from User-Provided Data

If BQ is unavailable or times out after 30 seconds, execute this fallback:

1. Ask: "BQ isn't responding. Can you share your account list? Options: (a) export CSV from CS Compass Overview, (b) paste a list with account name, GMV, and last activity date, or (c) tell me your top 5-10 accounts you're worried about."
2. From whatever the user provides, extract these fields (use whatever's available):

| Field | Required? | If Missing |
|-------|-----------|------------|
| Account name | Yes | Cannot triage without at least a name |
| GMV or revenue | Preferred | Skip financial health scoring, focus on engagement + foundation |
| Last activity date | Preferred | Skip engagement compliance check, focus on risk + foundation |
| Risk level | Optional | Default to "Unknown" — do NOT assume Low |
| Products adopted | Optional | Skip foundation stack check |

3. Apply a **reduced decision tree** based on what fields are present:

   **If you have risk_level + account name (minimum viable triage):**
   - Gate 1: risk_level = 'Imminent Churn' → 🔴 ESCALATE
   - Gate 2: risk_level = 'High' or 'Critical' → 🔴 ACT NOW
   - All others → 🟡 MONITOR ("Risk level OK, but insufficient data for full health assessment")
   - Skip Gates 3-7 entirely. Note: "Partial triage — risk-only. Run full triage when BQ is available."

   **If you have risk_level + GMV + last_activity_date (revenue-mcp or CSV):**
   - Gates 1-2: Risk level checks (as above)
   - Gate 3: `days_since_activity` > 30 AND `gmv_l365d` > $1M → 🔴 ACT NOW (high-value disengaged)
   - Gate 3b: `days_since_activity` > 30 AND `gmv_l365d` ≤ $1M → 🟡 MONITOR (engagement gap)
   - Gate 5: `gmv_growth_yoy` < -0.05 (if YoY available) → 🟡 MONITOR (declining)
   - Skip Gates 4, 6 (foundation/SP data unavailable). Note skipped dimensions.
   - All others → 🟢 HEALTHY (based on available data)

   **If you have full CSV export from CS Compass (includes health_score, foundation_status, sp_penetration):**
   - Apply full 7-gate decision tree from Step 2. Treat as equivalent to BQ query.
   - Note CSV date: "Data as of [export date] — may not reflect changes since then."

4. Always note which scoring dimensions were skipped: "⚠️ Partial triage — [list skipped dimensions]. Run full triage when BQ access is restored."

### Step 1c: Check Active Mitigations

Before classifying, check if any accounts already have mitigation actions in progress. If CS Compass Quick.db is accessible (via `quick-cs-compass` MCP or direct API):

```
Query collection: risk_mitigation_actions
Filter: status IN ('draft', 'pending_lead', 'pending_director', 'approved')
```

Build a lookup map: `account_id → {status, mitigation_type, flags_addressed, created_at}`. Use this in Gates 1-2 to avoid recommending duplicate actions.

If CS Compass is not accessible, note: "⚠️ Could not check active mitigations. Some flagged accounts may already have mitigation actions in progress — verify in CS Compass before creating new ones."

Also check `risk_overrides` collection for lead-approved risk category overrides:

```
Query collection: risk_overrides
Filter: status = 'active'
```

Build a lookup map: `account_id → {override_risk_category, flags_addressed, approved_by, approved_at, status, expired_at, reactivated_at}`.

**Override logic in Gates 1-2:**
- If account has an **active override** (`status = 'active'`, `expired_at` is null or in the future):
  - Use `override_risk_category` INSTEAD of the automated `risk_category` for gate classification
  - Show both in output: "Automated: CRITICAL → **Override: MODERATE** (approved by [lead] on [date], flags addressed: [list])"
  - Do NOT classify as 🔴 Act Now if the override downgrades the risk — the lead has already assessed this
  - DO flag as 🟡 Monitor with: "Active risk override — review at next 1:1 whether override is still valid"
- If override has **expired** (`expired_at` is in the past, no `reactivated_at`):
  - Use automated `risk_category` (override no longer applies)
  - Note: "⚠️ Previous override expired [date] — risk reverted to automated scoring"
- If override was **revoked then reactivated** (`reactivated_at` exists):
  - Use `override_risk_category` — the lead reinstated it
  - Note: "Override reactivated [date]: [reactivation_reason]"

### Step 2: Classify and Prioritize

For each account, walk through this decision tree. **Stop at the first YES** — each account gets exactly one classification.

**Gate 1: Auto-Critical Risk Flags**
- Does the account have ANY auto-critical flag? (TERMINATION, PAYOUT FREEZE, SP REJECTION, FRAUD, AUP OFFENSE, CHECKOUT INCIDENT, or `risk_level` = 'Imminent Churn')
  - **YES** → Check mitigation status first:
    - Has active mitigation (`pending_lead`, `pending_director`, or `approved`)? → 🔴 **ACT NOW — MITIGATION IN PROGRESS** | Reason: "Auto-critical: [flag name]. Mitigation status: [status]." | Action: "Do NOT create duplicate mitigation. Check existing action in CS Compass → Risk Mitigation tab. Escalate to lead if status is stale (>7 days in pending)."
    - No active mitigation? → 🔴 **ACT NOW — ESCALATE** | Reason: "Auto-critical: [flag name]. No mitigation in progress." | Action: "Escalate to lead immediately. Create mitigation action in CS Compass." | **Stop.**
  - **NO** → Continue to Gate 2.

**Gate 2: High/Critical Risk (risk_score ≥ 12)**
- Is `risk_category` = 'HIGH' (score 12-17) or 'CRITICAL' (score ≥ 18)?
  - **YES** → Check mitigation status:
    - Has active mitigation? → 🟡 **MONITOR — MITIGATION ACTIVE** | Reason: "Risk category [category] (score: [N]/29). Mitigation [status]. Flags: [flag list]." | Action: "Review mitigation progress. Ensure next steps are on track. Update lead at next 1:1."
    - No active mitigation AND `days_since_activity` > 30? → 🔴 **ACT NOW — URGENT** | Reason: "High risk (score: [N]/29) + disengaged ([N] days). Flags: [flag list]." | Action: "Schedule call this week. Review risk flags: [list specific flags and what each means]."
    - No active mitigation AND `days_since_activity` ≤ 30? → 🔴 **ACT NOW** | Reason: "High risk (score: [N]/29), recently engaged. Flags: [flag list]." | Action: "Review last interaction — are the flagged issues being addressed? Consider creating formal mitigation action."
  - **NO** → Continue to Gate 3.

**Gate 3: Engagement Overdue**
- Look up the target sync frequency using the account's `segment` + `priority_tier`:
  - Large Accounts + High Priority → target = **7 days**
  - Large Accounts + Medium Priority → target = **14 days**
  - Large Accounts + Low Priority → target = **30 days**
  - Mid-Market Assigned + High Priority → target = **14 days**
  - Mid-Market Assigned + Medium Priority → target = **30 days**
  - Mid-Market Assigned + Low Priority → target = **90 days**
  - Mid-Market Scaled / Unicorn + High Priority → target = **30 days**
  - Mid-Market Scaled / Unicorn + Medium Priority → target = **90 days**
  - Mid-Market Scaled / Unicorn + Low Priority → target = **180 days**
- Is `days_since_activity` > target?
  - **YES** → Is `gmv_l365d` > $5,000,000?
    - **YES** → 🔴 **ACT NOW** | Reason: "High-value account overdue — last contact [N] days ago (target: [target] days for [segment]/[tier])." | Action: "Prioritize outreach this week — large accounts disengaging is high-churn-risk."
    - **NO** → 🟡 **MONITOR** | Reason: "Engagement overdue — [N] days since last activity (target: [target] days)." | Action: "Schedule check-in within the next [target] days."
  - **NO** → Continue to Gate 4.

**Gate 4: Foundation Stack Gap**
- Is `foundation_status` = 'At Risk'? (missing Shopify Payments OR Shop Pay)
  - **YES** → Is `gmv_l365d` > $1,000,000?
    - **YES** → 🟡 **MONITOR — HIGH VALUE** | Reason: "Large merchant missing foundation products." | Action: "Investigate — is external payment processing intentional, or is this an adoption opportunity worth $[estimated SP revenue]?"
    - **NO** → 🟡 **MONITOR** | Reason: "Foundation stack incomplete." | Action: "Add Payments/Shop Pay adoption to next call agenda."
  - **NO** → Continue to Gate 5.

**Gate 5: Financial Decline**
- Is `gmv_growth_yoy` < -0.05 (declining 5%+)?
  - **YES** → Is `gmv_growth_qoq` also < -0.10 (accelerating decline)?
    - **YES** → 🟡 **MONITOR — ACCELERATING** | Reason: "GMV declining YoY and accelerating QoQ." | Action: "Investigate root cause — seasonal? competitive loss? platform issue?"
    - **NO** → 🟡 **MONITOR** | Reason: "GMV declining YoY but stabilizing." | Action: "Track next quarter — may be seasonal."
  - **NO** → Continue to Gate 6.

**Gate 6: SP Penetration**
- Is `sp_penetration` < 0.40?
  - **YES** → 🟡 **MONITOR** | Reason: "Low SP penetration ([X]%)." | Action: "Discuss payment processing strategy at next touchpoint."
  - **NO** → Continue to Gate 7.

**Gate 6b: Atrophying Trajectory**
- Is the account's RHS tier = 'Atrophying' (score 7-14, engagement declining)?
  - **YES** → Is `rhs_engagement` < 2 (nearly disengaged)?
    - **YES** → 🟡 **MONITOR — ATROPHYING + DISENGAGED** | Reason: "Declining trajectory with low engagement (RHS score [N], engagement [N]/12)." | Action: "Proactive outreach before this becomes At Risk. Add to next call rotation."
    - **NO** → 🟡 **MONITOR — ATROPHYING** | Reason: "Declining trajectory but still engaged (RHS [N], engagement [N]/12)." | Action: "Track at next touchpoint — is the decline seasonal or structural?"
  - **NO** → Continue to Gate 7.

**Gate 7: Healthy**
- All checks passed → 🟢 **HEALTHY** | No action required. Include in summary table.

**Portfolio-size normalization**: After classifying all accounts, check the output balance. A useful triage for a 20-50 account book should produce:
- **🔴 Act Now: 3-5 accounts max.** If more than 5, re-prioritize — only auto-critical and highest risk_score + disengaged accounts stay in 🔴. Demote others to 🟡 with note: "Lower-priority risk — address after top 5."
- **🟡 Monitor: 5-15 accounts.** This is the working list. If more than 15, group by reason (foundation gaps, engagement gaps, declining GMV) for easier scanning.
- **🟢 Healthy: remainder.** Summary table only.
- If classification produces >50% 🔴, something is wrong — check if data quality issue or if segment is genuinely in crisis (flag for lead).

**Priority tier derivation**: Rank accounts within segment by `health_score` descending. Bottom 20% → High Priority, middle 45% → Medium Priority, top 35% → Low Priority. If <5 accounts in segment, use absolute thresholds: <55 High, 55-75 Medium, >75 Low.

### Step 2b: Determine Escalation Level

For each 🔴 Act Now account, classify the required response:

| Condition | Response Level | Who Acts |
|-----------|---------------|----------|
| `risk_level` = 'Imminent Churn' | **🚨 ESCALATE** | CSM notifies lead immediately. Lead may involve director. |
| `risk_level` = 'Critical' AND `days_since_activity` > 30 | **🚨 ESCALATE** | CSM + lead align on action plan within 48h. |
| `gmv_l365d` > $5,000,000 AND `gmv_growth_yoy` < -0.20 | **🚨 ESCALATE** | High-value account in steep decline — lead awareness required. |
| `risk_level` = 'High' (without above conditions) | **⚡ CSM ACTION** | CSM owns the response. Schedule call, review account, prepare talking points. Update lead at next 1:1. |
| Engagement overdue (Gate 3) | **⚡ CSM ACTION** | CSM schedules touchpoint. No escalation unless account is also high-risk. |
| Foundation gap or declining GMV (Gates 4-5) | **📋 CSM PLAN** | CSM adds to next call agenda. Track over time. Mention to lead if pattern persists across multiple accounts. |

### Step 3: Generate Triage Output

Produce the prioritized report. Shape output to the portfolio size:
- **≤ 15 accounts** → Full detail for EVERY account (all tiers)
- **16-30 accounts** → Full detail for 🔴 and 🟡, summary table for 🟢
- **31-50 accounts** → Full detail for 🔴 only, condensed list for 🟡, count-only for 🟢
- **50+ accounts** → Confirm scope first, then apply 31-50 pattern

---

## Output Template

```markdown
# Portfolio Triage: [CSM Name]
**Segment:** [Segment] | **Lead:** [Lead Name] | **Accounts:** [N] | **Date:** [Today]

## Summary
- 🔴 **Act Now:** [N] accounts — [brief reason summary]
- 🟡 **Monitor:** [N] accounts — [brief reason summary]
- 🟢 **Healthy:** [N] accounts

## 🔴 Act Now

### [Account Name] — [Risk reason]
- **GMV:** $[X] | **Revenue L12M:** $[X] | **YoY:** [+/-X%]
- **Risk Level:** [High/Critical] | **Health Score:** [X]/100
- **Journey Stage:** [Stage] | **Foundation:** [Strong/Building/At Risk]
- **Last Activity:** [Date] ([N] days ago) | **L90 Touches:** [N]
- **Risk Score:** [N]/29 | **Flags:** [list specific flags from the 21-flag taxonomy]
- **Mitigation:** [None / Draft by CSM / Pending lead approval / In progress — started DATE]
- **Why flagged:** [Specific reason — e.g., "Risk score 15/29 (HIGH). Flags: Negative YoY, QoQ Decline, Escalated Tickets. No activity in 45 days."]
- **Suggested action:** [Specific next step — account for mitigation status. If mitigation exists, suggest reviewing progress, not creating a new one.]

### [Next account...]

## 🟡 Monitor

### [Account Name] — [Monitor reason]
- [Same fields, condensed]
- **Why flagged:** [Reason]
- **Suggested action:** [Next step]

## 🟢 Healthy ([N] accounts)

| Account | GMV L365D | YoY | Health | Foundation | Last Activity |
|---------|-----------|-----|--------|------------|---------------|
| [Name]  | $[X]      | [X%]| [X]   | [Status]   | [N] days ago  |

---
**Portfolio Health:** [X]% accounts healthy | [X]% at risk | [X]% needing action
**Foundation Stack:** [X]% Strong | [X]% Building | [X]% At Risk
**Engagement:** [X]% on track | [X]% overdue
**Top opportunity:** [Biggest GMV account with foundation gap or low SP penetration]
```

**Conditional sections:**
- If **0 accounts in Act Now** → Replace section with: "✅ No critical accounts today."
- If **portfolio > 30 accounts** → Show Healthy as summary table only, no per-account detail
- If **portfolio ≤ 15 accounts** → Show all accounts with full detail regardless of status
- If **Lead is requesting for their team** → Add team-level rollup header comparing CSMs

---

## Error Handling

| Scenario | Action |
|----------|--------|
| BQ unavailable or query times out | Cannot proceed. Tell user: "Portfolio triage requires live BigQuery data. Check your MCP connection or try again shortly." Do NOT guess or use stale data. |
| CSM email returns 0 accounts | Verify email spelling. Try partial match: `LIKE '%lastname%'`. If still 0: "No accounts found for this email. The CSM may be inactive, on leave, or recently reassigned. Check `sales_accounts` directly or ask their lead." |
| Multiple CSMs share the same lead | This is normal — the query filters by CSM email, not lead. If user asks for "my team," they want `coaching-session-prep` or `cs-lead-digest`, not this skill. |
| Account has NULL GMV/revenue | Flag in output: "⚠️ Missing financial data — account may be very new or have a data lag. Verify in Salesforce." Do NOT exclude from triage. |
| All accounts show 999 days_since_activity | Likely a data source issue with the activities table, not genuinely 0 engagement. Note: "⚠️ Activity data may be stale — verify recent meetings in Salesforce or calendar." |
| Account has risk_level = 'Imminent Churn' | Escalate to top of 🔴 Act Now. Add: "🚨 IMMINENT CHURN — escalate to lead immediately if not already flagged." |
| Segment returns 'N/A' | CSM's manager isn't in the CS Leads list. Note the gap but proceed with triage using default engagement targets (Mid-Market Scaled). |
| User asks for historical comparison | This skill triages current state only. For trends: "I can show today's portfolio health. For historical trend analysis, check CS Compass dashboards or run `nrr-pacing` for revenue trends." |
| User asks to update Salesforce risk level | Out of scope. Direct to: "Use `sf-writer` to update Salesforce fields, or `risk-mitigation-playbook` to create a formal risk mitigation action." |
| Health score returns NULL for an account | Means one or more scoring dimensions had no data. Do NOT exclude the account. Display as "Health: N/A (incomplete data)" and list which inputs were missing (GMV? Risk level? SP penetration?). Move to 🟡 Monitor with reason "Incomplete health data — verify in Salesforce." |
| Account has mismatched segment (e.g., Large Account CSM with Mid-Market lead mapping) | Use the segment returned by the query, not the CSM's assumed segment. Note the mismatch: "⚠️ Segment derived from lead mapping — verify if account was recently reassigned." Apply engagement targets for the returned segment. |
| Partial data — some accounts have metrics, others don't | Proceed with available data. Group incomplete accounts separately at the end of the 🟡 Monitor section: "### ⚠️ Incomplete Data ([N] accounts)" with a note on what's missing per account. Do NOT silently drop them. |
| Query returns > 100 accounts | Unusual for a single CSM. Likely queried by lead email instead of CSM email, or the CSM has interim coverage of another book. Confirm with user: "Found [N] accounts — is this correct, or should I filter to a specific segment?" |
| Escalation decision — when to flag for lead | Always escalate to 🔴 Act Now (recommend lead notification) if: risk_level = 'Imminent Churn', OR risk_level = 'Critical' AND days_since_activity > 30, OR GMV > $5M AND gmv_growth_yoy < -0.20. For all other 🔴 items, recommend CSM self-action first. |

---

## Anti-Patterns

- Do NOT rank accounts solely by GMV. A $10M account with 20% YoY growth and Strong foundation is healthy — a $500K account with -15% YoY, no Payments, and 60 days no contact is the real priority. **Priority is driven by risk and engagement gaps, not account size.**
- Do NOT treat `days_since_activity = 999` as "never contacted." It means no meetings/calls in `report_post_sales_dashboard_activities` in the last 90 days — the CSM may have logged interactions in Salesforce directly, via email, or in Salesloft.
- Do NOT confuse **coverage assignment** (`sales_accounts.merchant_success_manager`) with **compensation assignment** (`shop_net_revenue_retention_v3.msm_id`). This skill uses coverage assignment — it shows who's *currently managing* the account. During LOA coverage, the covering CSM sees the accounts here, but the original CSM still owns the NRR. Use `nrr-pacing` for compensation-aligned data.
- Do NOT generate mitigation plans. Flag the risk, suggest the next single action, and direct to `risk-mitigation-playbook` for full mitigation workflow with approval chains.
- Do NOT skip the foundation stack check. Missing Shopify Payments or Shop Pay on a Plus merchant is always a flag — even if health_score > 75. SP penetration below 40% represents concrete revenue leakage.
- Do NOT present raw `copilot_account_attributes` numbers without context. Always compare to segment peers: "GMV $2.3M (47th percentile in Mid-Market Scaled)" is actionable; "$2.3M GMV" alone is not.
- Do NOT triage without verifying the `sales_users.is_active = TRUE` filter. Inactive CSMs still have account records but shouldn't appear in live triage — this causes ghost portfolios.
- Do NOT surface `sf_risk_level` from Salesforce without noting it may be stale. Salesforce risk is manually set by account teams — check `days_since_activity` and `gmv_growth_yoy` as leading indicators even if SF says "Low."

## Related Skills

| Need | Skill | When to Hand Off |
|------|-------|-----------------|
| Revenue forecast for this portfolio | `nrr-pacing` | After triage, user asks "how am I tracking against quota" |
| Deep-dive on a specific at-risk account | `risk-mitigation-playbook` | User selects a 🔴 account and wants a formal mitigation plan |
| Prepare for a coaching 1:1 about this CSM | `coaching-session-prep` | Lead wants to discuss portfolio performance with the CSM |
| Score a recent call with a flagged account | `csm-call-scoring` | CSM had a call with a 🔴 account, wants to evaluate quality |
| Check product adoption gaps across the book | `foundation-stack-analysis` | Multiple 🟡 accounts flagged for foundation gaps |
| Pull full context on an account before a call | `account-context-sync` | CSM picks a flagged account and wants all available context |
