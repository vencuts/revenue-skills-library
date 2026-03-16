---
name: opp-compliance-checker
description: Validate a Salesforce opportunity against Revenue Rules of Engagement (RoE) — checks territory ownership, account assignment, opp creation standards, crediting rules, and data completeness. Use when asked to "check this opp", "validate opportunity", "is this opp compliant", "RoE check", "territory check", "who owns this account", or when opp-hygiene flags a deal for deeper review. Works for AEs, Rev Ops, and sales managers validating pipeline quality.
---

# Opp Compliance Checker

Validate a Salesforce opportunity against Revenue Rules of Engagement. **UAL ownership check is always step 1** — most compliance issues are territory or account assignment problems.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | UAL ownership check, SF opp details, activity signals, enriched account data | ⚠️ Critical tool. Without BQ: "Cannot validate — BQ access required for UAL and Salesforce data." Draft checklist for manual validation. |
| `slack_search` | Check #rev-ops-escalations or deal channels for context on this opp | Skip prior discussion context. Note: "No Slack history checked — recommend verifying with Rev Ops if flags found." |
| `vault_search` | Territory assignments, manager structure, RoE policy docs | Use inline RoE knowledge. Note: "Verify current RoE version — policy may have updated." |

**Critical dependency: `query_bq` is required.** Compliance checking is fundamentally data-driven — cannot validate without querying UAL and Salesforce.

---

## Workflow

### Step 0: Get Opp Details + Data Integrity Pre-Flight

User provides one of:
- Salesforce Opportunity ID → query SF directly
- Company name + domain → look up in UAL first
- Opp URL → extract ID from URL

Once you have the account_id, run `data-integrity-check` — duplicate accounts splitting pipeline across two reps is the #1 compliance issue that this skill misses without it. If territory owner is inactive or worker attributes are missing, flag these in your compliance report as upstream data issues (not the rep's fault).

If opp ID available, pull opp details:

```sql
SELECT
  o.Id, o.Name, o.StageName, o.Amount, o.CloseDate,
  o.OwnerId, o.AccountId, o.CreatedDate,
  o.Primary_Product_Interest__c, o.Type,
  u.Name AS owner_name
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
LEFT JOIN (
  SELECT Id, Name, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY _sdc_extracted_at DESC) rn
  FROM `shopify-dw.raw_salesforce_banff.user`
) u ON o.OwnerId = u.Id AND u.rn = 1
WHERE o.Id = @opp_id
LIMIT 1
```

### Step 1: UAL Ownership & Territory Validation (ALWAYS FIRST)

Check if the account is correctly assigned:

```sql
WITH ual AS (
  SELECT
    COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
    COALESCE(account_owner, sales_rep, d2c_sales_rep) AS ual_owner,
    territory_name AS ual_territory,
    account_id AS ual_sf_account_id,
    LOWER(REGEXP_REPLACE(IFNULL(COALESCE(domain, domain_sf, domain_3p, domain_1p), ''),
      r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS normalized_domain
  FROM `sdp-prd-commercial.mart.unified_account_list`
  WHERE account_id = @sf_account_id
     OR LOWER(COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p))
        LIKE CONCAT('%', LOWER(@company_name), '%')
)
SELECT * FROM ual LIMIT 10
```

**Compliance checks:**

| Check | Pass | Fail |
|---|---|---|
| Opp owner = UAL account owner | ✅ Correctly assigned | 🔴 **Territory violation** — opp owner differs from UAL account owner |
| Account exists in UAL | ✅ Known account | 🟡 **Unregistered account** — may need account creation process |
| Single UAL match | ✅ Clean | 🟡 **Multiple matches** — potential duplicate accounts |
| Territory matches rep's assigned territory | ✅ In territory | 🔴 **Out-of-territory opp** — rep working account outside their assignment |

### Step 1.5: Enriched Opp Context

Pull additional fields from the enriched mart for deeper compliance checks:

```sql
SELECT o.compelling_event, o.market_segment, o.team_segment,
  o.territory_name, o.salesforce_owner_name, o.forecast_category,
  o.description, o.next_step
FROM `shopify-dw.sales.sales_opportunities` o
WHERE o.opportunity_id = @opp_id
LIMIT 1
```

Also check account grade and segment alignment:

```sql
SELECT a.account_grade, a.account_priority_d2c, a.territory_segment,
  a.ecomm_platform, a.sales_lifecycle_stage
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.account_id = @sf_account_id
LIMIT 1
```

### Step 2: Opp Creation Standards

Check against Rules of Engagement criteria:

| Rule | How to Check | Flag |
|---|---|---|
| **Qualifying conversation happened** | Check Salesloft calls (Tier 1+2 match) + SF activity | 🔴 if 0 connected calls AND 0 merchant replies |
| **Not self-serve motion** | Check if merchant is on a self-serve plan path | 🟡 if merchant signed up < 30 days before opp creation |
| **Creditable revenue** | Check if primary product generates Billed Revenue | 🔴 if product = free tier or non-rev |
| **Opp created after conversation** | Compare opp CreatedDate vs first activity date | 🟡 if opp created same day as first outreach |
| **Reasonable close date** | Check close date vs created date | 🟡 if close date < 7 days from creation (speed deal?) OR > 365 days (stale) |
| **Compelling event documented** | Check `compelling_event` from enriched opp | 🟡 if blank — opp created without a reason |
| **Segment alignment** | Compare opp `market_segment` vs account `territory_segment` | 🟡 if mismatch (e.g., Enterprise rep on SMB account) |

### Step 3: Data Completeness

Check required fields are populated:

```
- [ ] Primary Product Interest filled
- [ ] Close Date set and reasonable
- [ ] Amount > $0
- [ ] Stage not "Prospecting" for > 30 days
- [ ] Account has associated website/domain
- [ ] Owner is active (not departed rep)
- [ ] Next Steps field populated (for open opps)
```

### Step 4: Activity Validation

Query for engagement signals:

```sql
SELECT
  COUNT(DISTINCT CASE WHEN activity_type = 'Call' THEN activity_id END) AS calls,
  COUNT(DISTINCT CASE WHEN activity_type = 'Email' AND direction = 'Inbound' THEN activity_id END) AS merchant_emails,
  COUNT(DISTINCT CASE WHEN activity_type = 'Meeting' THEN activity_id END) AS meetings,
  MIN(activity_date) AS first_activity,
  MAX(activity_date) AS last_activity
FROM `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity`
WHERE opportunity_id = @opp_id OR account_id = @account_id
```

### Step 5: Generate Compliance Report

```
## ✅/⚠️/🔴 Opp Compliance Report: [Opp Name]
**Opp ID:** [ID] | **Owner:** [Name] | **Stage:** [Stage] | **Amount:** $[X]

### Territory & Ownership
| Check | Status | Details |
|---|---|---|
| UAL account owner matches opp owner | ✅/🔴 | UAL says [owner], opp says [owner] |
| Account in UAL | ✅/🟡 | [Found/Not found] |
| Territory alignment | ✅/🔴 | UAL territory: [X], Rep territory: [Y] |

### Creation Standards
| Check | Status | Details |
|---|---|---|
| Qualifying conversation | ✅/🔴 | [N] calls, [N] merchant replies before opp creation |
| Not self-serve | ✅/🟡 | [Evidence] |
| Creditable revenue | ✅/🔴 | Product: [X], generates Billed Revenue: [Y/N] |
| Timing | ✅/🟡 | Created [N] days after first activity |

### Enriched Checks
| Check | Status | Details |
|---|---|---|
| Compelling event | ✅/🟡 | [event text or "Blank — no reason documented"] |
| Segment alignment | ✅/🟡 | Opp: [market_segment], Account: [territory_segment] |
| Account grade | ℹ️ | [grade] — [appropriate for this rep's segment?] |

### Data Completeness
[Checklist with ✅/❌ per field]

### Activity Summary
- **Calls:** [N] | **Merchant Emails:** [N] | **Meetings:** [N]
- **First activity:** [Date] | **Last activity:** [Date]
- **Opp age:** [N] days | **Days since last activity:** [N]

### Verdict
**[COMPLIANT / NEEDS REVIEW / NON-COMPLIANT]**
[One paragraph explaining the key finding and recommended action]
```

---

## Severity Levels

| Level | Meaning | Action |
|---|---|---|
| 🔴 **Non-compliant** | Territory violation, no qualifying conversation, or non-creditable revenue | Flag to manager, do not count in pipeline |
| 🟡 **Needs review** | Borderline issues (timing, missing fields, unregistered account) | Manager should review and either fix or remove |
| ✅ **Compliant** | Passes all checks | Good to count in pipeline |

---

## Output Format

Shape report based on compliance result:

### If COMPLIANT (✅)
```
✅ Opp Compliance: PASS
- Territory: [Owner] matches UAL owner ✓
- Qualifying conversation: [Evidence] ✓
- Creditable revenue: [Reason] ✓
- Data completeness: All required fields populated ✓
Summary: No issues found. Opp is compliant with Revenue RoE.
```

### If NON-COMPLIANT (🔴)
```
🔴 Opp Compliance: FAIL — [Primary Violation]
Violations:
1. [Rule violated] — [Evidence] — [Severity]
2. [Rule violated] — [Evidence] — [Severity]
Recommendation: [Specific action — reassign, remove, escalate]
Coaching question for manager: "[Question to ask the rep]"
```

### If NEEDS REVIEW (🟡)
```
🟡 Opp Compliance: REVIEW NEEDED
Findings:
1. [Borderline issue] — [Evidence] — [Why it's ambiguous]
Recommendation: Manager should verify [specific thing] before counting in pipeline.
```

### Conditional Sections
- **Territory Conflict Details** (only when UAL shows different owner): Include both owners, territory names, and recommendation
- **Activity Timeline** (only when activity data reveals patterns): Chronological activity with gaps highlighted
- **Duplicate Account Warning** (only when UAL returns multiple matches): All matches with domains and owners

## Error Handling

| Scenario | Action |
|----------|--------|
| UAL check fails (BQ access denied) | Note: "⚠️ Cannot verify ownership — UAL check skipped." Proceed with SF data only. Add "UNVERIFIED" banner to report. |
| Opp ID not found in Salesforce | Try: (1) search by company name + domain in UAL, (2) check for merged/deleted opps. If still nothing: "Opp may have been deleted or ID is incorrect." |
| Activity query returns 0 rows | Flag: "Zero activity logged — this is a compliance red flag in itself. An opp with no connected calls or emails is suspect." |
| BQ access denied on `sdp-prd-commercial.mart.unified_account_list` | Use `raw_salesforce_banff` tables as fallback for ownership check. Note: "Using SF data only — UAL cross-reference unavailable." |
| UAL shows account owned by departed/inactive rep | Flag: "Account owner {name} appears inactive. Territory may need reassignment before this opp can be credited." |
| Multiple UAL entries for same domain (different accounts) | Report all matches. Flag: "Duplicate accounts detected — account consolidation needed before compliance can be fully assessed." |
| Opp was created very recently (< 24 hours ago) | Note: "Opp created {N} hours ago — some activity data may not have synced to BQ yet. Re-check in 24h if compliance assessment is inconclusive." |
| User is the opp owner asking about their own deal | Provide assessment objectively. Do NOT soften language. "This is your opp — flags found need to be addressed regardless of ownership." |

---

## Integration

- **opp-hygiene** catches patterns (premature creation, self-serve claims) → this skill validates against RoE rules
- **prospect-researcher** validates ownership before opp creation → this validates after
- **diana-dashboard** pipeline metrics depend on clean opps → this skill ensures cleanliness
- **UAL Reference** — full fuzzy matching query: see `references/company-lookup-ual-query.md`
