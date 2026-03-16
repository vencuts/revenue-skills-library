---
name: data-integrity-check
description: Pre-flight data quality check for any Salesforce account, opportunity, or rep record. Run this BEFORE any revenue skill that queries SF/UAL data. Returns a confidence envelope with warnings about duplicates, null fields, inactive territory owners, and missing worker attributes. Use when starting any account research, deal analysis, opp review, or pipeline assessment — or when another skill says "run data-integrity-check first." Triggers on account ID, opportunity ID, rep email, or when any revenue skill needs to validate its input data.
---

# Data Integrity Check — Pre-Flight for Revenue Skills

> **Purpose**: Every revenue skill that touches Salesforce or UAL data should run this check first.
> Bad data in → bad analysis out. This skill catches the problem at the source.

## When to Run

This is **Layer 0** — the data quality gate that runs before analysis begins.

- Another skill asks you to validate an account, opp, or rep
- User asks to "check data quality" or "verify this account"
- You're about to run account-research, opp-compliance-checker, deal-prioritization, opp-hygiene, prospect-researcher, meeting-prep, deal-followup, sf-writer, account-context-sync, or qualification-trainer on a specific account/opp/rep
- User says "why does this data look wrong" or "something's off with this account"

## Tools & Data Sources

| Tool | Table / Source | What It Checks |
|------|---------------|----------------|
| `query_bq` | `sdp-prd-commercial.mart.unified_account_list` | UAL record completeness — null region, fit scores, revenue, service model, industry, country |
| `query_bq` | `shopify-dw.raw_salesforce_banff.account` | Account duplicates by name/website, account ownership |
| `query_bq` | `shopify-dw.scratch.TI_territories_with_inactive_users` | Territory owner inactive — coverage gap |
| `query_bq` | `shopify-dw.scratch.TI_territories_with_no_accounts` | Territory exists but has zero accounts assigned |
| `query_bq` | `shopify-dw.scratch.worker_current_null_sales_attributes_where_sales_team_not_null` | Rep missing required attributes (region, segment, LOB, vertical) |
| `query_bq` | `shopify-dw.scratch.UAL_data_quality_check_SP_null_*` | Specific UAL field null checks (20 tables, one per field) |

## Workflow

### Step 1: Identify the Entity

Determine what the user or calling skill provided:
- **Account ID** (starts with `001`) → run checks A, B, C
- **Opportunity ID** (starts with `006`) → look up account_id from opp first, then run A, B, C, D
- **Rep email** → run check D, E
- **Account name** (string) → run check A first to find account_id, then B, C

If input is ambiguous, ask: "I need an account ID, opportunity ID, or rep email to run the integrity check. Which do you have?"

### Step 2: Run Checks (parallel when possible)

**Check A — Account Duplicates**
```sql
SELECT account_id, account_name, website, owner_id, owner_name
FROM `shopify-dw.raw_salesforce_banff.account`
WHERE LOWER(account_name) LIKE LOWER(@name_pattern)
   OR LOWER(website) LIKE LOWER(@website_pattern)
ORDER BY account_name
LIMIT 20
```
- If >1 row returned with different account_ids → ⚠️ DUPLICATE ACCOUNTS
- Note which has active opps, which has the most recent activity

**Check B — UAL Record Completeness**
```sql
SELECT
  account_id, account_name, region, country, industry,
  service_model, estimated_total_annual_revenue,
  estimated_online_annual_revenue, estimated_offline_annual_revenue,
  d2c_fit_score, b2b_fit_score, retail_fit_score,
  account_owner_email, merchant_success_manager_id,
  location_count_3p, company_description_3p, tags
FROM `sdp-prd-commercial.mart.unified_account_list`
WHERE account_id = @account_id
LIMIT 1
```
- Count null fields. Each null = one warning.
- Critical nulls (confidence-killing): `region`, `service_model`, `estimated_total_annual_revenue`, `account_owner_email`
- Important nulls (analysis-limiting): fit scores, industry, country, location count
- Minor nulls (nice-to-have): tags, company_description_3p

**Check C — Territory Health**
```sql
SELECT *
FROM `shopify-dw.scratch.TI_territories_with_inactive_users`
WHERE territory_id IN (
  SELECT territory_id
  FROM `shopify-dw.scratch.TI_territories_accounts_relationships_initial_extract`
  WHERE account_id = @account_id
)
```
- If rows returned → ⚠️ TERRITORY HAS INACTIVE OWNER
- Also check: `TI_territories_with_no_employees`, `TI_territories_with_inconsistent_lobs`

**Check D — Worker Sales Attributes**
```sql
SELECT *
FROM `shopify-dw.scratch.worker_current_null_sales_attributes_where_sales_team_not_null`
WHERE worker_email = @rep_email
```
- If row returned → ⚠️ REP MISSING ATTRIBUTES — list which ones are null
- Missing attributes break assignment automation downstream

**Check E — Contact Duplicates** (if contact email provided)
```sql
SELECT contact_id, first_name, last_name, email, account_id, account_name
FROM `shopify-dw.raw_salesforce_banff.contact`
WHERE LOWER(email) = LOWER(@email)
ORDER BY last_modified_date DESC
LIMIT 10
```
- If >1 row → ⚠️ DUPLICATE CONTACTS

### Step 3: Compute Confidence Envelope

Score the data quality:

| Condition | Confidence Impact |
|-----------|------------------|
| No warnings | HIGH ✅ |
| 1-2 minor null fields | HIGH ✅ (with notes) |
| Critical null (region, service_model, revenue, owner) | MEDIUM ⚠️ |
| Duplicate accounts found | MEDIUM ⚠️ |
| Territory owner inactive | MEDIUM ⚠️ |
| Rep missing attributes | MEDIUM ⚠️ |
| 3+ critical nulls | LOW 🔴 |
| Duplicate accounts + territory inactive | LOW 🔴 |
| No UAL record found at all | LOW 🔴 |

### Step 4: Return the Envelope

```
## Data Integrity Report: [Account Name]

**Confidence: HIGH/MEDIUM/LOW**
**Data Quality Score: X/10** (10 = pristine, 0 = unusable)

### ⚠️ Warnings
- [List each warning with specific field/value]

### ✅ Verified Clean
- [List checks that passed]

### Impact on Analysis
- [What these warnings mean for downstream skills]
- [Which recommendations should be treated with lower confidence]

### Recommended Actions
- [Specific cleanup steps — e.g., "Merge duplicate account 001ABC into 001DEF"]
- [Who to contact — e.g., "Territory owner inactive — escalate to RevOps"]
```

## Error Handling

| Scenario | Response |
|----------|----------|
| BQ query returns 403 (no access to `sdp-prd-commercial`) | Report: "Cannot access UAL table — need `sdp-prd-commercial` permissions via CloudDo. Skipping UAL completeness check. Confidence UNKNOWN for UAL fields." Run remaining checks. |
| Account not found in UAL | Report: "Account not in Unified Account List — may be a new/unassigned account. Confidence LOW for any UAL-dependent analysis." |
| Scratch tables don't exist | Report: "Territory/worker scratch tables not found — Molly's data quality pipeline may not have run yet. Skipping territory/worker checks." |
| BQ query timeout | Retry once. If still fails, skip that check and note it in the report. |
| Multiple accounts match name pattern | List all matches. Ask user to confirm which account_id to check. |
| Input is neither ID nor email | Ask: "I need a Salesforce account ID (001...), opportunity ID (006...), or rep email. What do you have?" |

## Scope Boundaries

- This skill checks data QUALITY, not data MEANING. It tells you "this field is null" not "this deal is bad."
- It does NOT write to Salesforce. It's read-only. For fixes, it recommends actions for humans.
- It does NOT replace the analysis skills. It prepares the ground for them.
- It does NOT check merchant-side data (storefront, product catalog). That's `merchant-health-report`.
- **Domain vocabulary**: UAL (Unified Account List), territory, service model, fit score (d2c/b2b/retail), LOB (Line of Business), worker attributes, account owner, MSM (Merchant Success Manager), assignment automation

## Integration Pattern for Other Skills

Other skills should add this as Step 0 in their workflow:

```
Step 0: If working with a specific account/opp/rep, invoke data-integrity-check.
        If confidence is LOW, prepend warnings to your output.
        If confidence is MEDIUM, note warnings but proceed.
        If confidence is HIGH, proceed normally.
```

Skills that MUST run this first: prospect-researcher, opp-compliance-checker, account-research, opp-hygiene, deal-prioritization, sf-writer, account-context-sync, meeting-prep, deal-followup, qualification-trainer.

---

**Version:** v1.0
**Source:** Molly Parapini's 5 data quality tools (workersalesattributecheck, ualinspector, territoryinspector, salesforcecontactdupecheck, salesforceaccountdupecheck)
