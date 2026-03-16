---
name: opp-hygiene
description: Assess Salesforce opportunity hygiene — identifies pipeline noise, premature opp creation, self-serve misattribution, and crediting issues. Use when reviewing closed-lost deals, auditing pipeline quality, coaching on opp creation standards, or when Loss Intelligence flags low-engagement deals. Work in progress — patterns added as new cases are assessed.
---

# Opp Hygiene

**Status: 🚧 Work in Progress** — Pattern library growing as deals are assessed.

## Purpose

Catch bad opps before they pollute pipeline metrics. Sits upstream of loss intelligence, deal coaching, and attainment reporting. A deal that should never have been created isn't a loss — it's noise.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Pull opp details from Salesforce, UAL lookup, activity signals, enriched loss fields | Ask user to paste opp details manually; flag that assessment will be less reliable |
| `slack_search` | Check #help-rev-ops or team channels for prior discussion of the opp | Skip "prior discussion" context; note it wasn't checked |
| `vault_search` | Look up rep/manager context, territory assignments | Provide assessment without org context |

## Workflow

### Step 0: Route by Input Type

After routing to opp, run `data-integrity-check` on its account_id. If confidence LOW (dupes, null UAL fields, inactive territory), lead your assessment with those warnings — the opp may look dirty because the underlying data IS dirty.

```
User provides...
│
├── Opp ID or URL → Step 1: Pull opp details
│   └── If opp not found → "Opp may be deleted. Check ID/URL."
│
├── Merchant name → Search SF for matching opps:
│   ├── 0 matches → "No opps found. Try domain search or alternate name."
│   ├── 1 match → Confirm with user → Step 1
│   └── Multiple → List all with stage + amount. "Which opp?"
│
├── "Review my pipeline" →
│   └── Ask: "Which specific opp? I assess one at a time." 
│       Do NOT audit an entire pipeline — each opp needs individual review.
│
├── Loss Intelligence flagged a deal →
│   ├── Has enriched loss fields? → Pull them → Step 2 (pattern matching)
│   └── No enriched fields? → Pull raw opp → Step 1 (manual assessment)
│
└── No specific input → Ask: "Give me an opp ID, merchant name, or Salesforce URL."
```

### Step 1: Pull Opp Details + Activity

```sql
SELECT o.opportunity_id, o.opportunity_name, o.amount, o.stage_name,
  o.created_at, o.close_date, o.loss_reason, o.primary_result_reason,
  o.primary_product_interest, u.name AS owner_name,
  a.name AS account_name, a.account_id
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
LEFT JOIN `shopify-dw.base.base__salesforce_banff_users` u ON o.owner_id = u.user_id
LEFT JOIN `shopify-dw.base.base__salesforce_banff_accounts` a ON o.account_id = a.account_id
WHERE o.opportunity_id = @opp_id AND o.is_deleted = FALSE
LIMIT 1
```

**Then check activity signals:**
```sql
SELECT activity_type, COUNT(*) AS count, MIN(activity_date) AS first_activity,
  MAX(activity_date) AS last_activity
FROM `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity`
WHERE opportunity_id = @opp_id
GROUP BY activity_type
```

**Interpret**:
- Zero total activity → 🔴 Red flag: "No logged activity. Was there a qualifying conversation?"
- Only outbound emails, no calls → 🟡 Possible self-serve or premature creation
- First activity > created_at → AE may have back-dated or created opp before engaging
- Last activity > 14 days before close_date → Deal went cold before close

### Step 2: Check Against Patterns

## Core Principle

**Outreach is not pipeline.** An opportunity gets created when there's a two-way conversation about a specific product with a creditable path to revenue. Everything before that is prospecting activity and belongs in Salesloft, not Salesforce.

## Opp Creation Criteria

Before creating an opp, the AE should be able to answer YES to all three:

1. **Was there a qualifying two-way conversation?** — The merchant expressed interest, not just the AE reaching out.
2. **Is this a sales-assisted motion?** — The merchant isn't already self-serving the same outcome.
3. **Does the AE have a creditable path to revenue?** — Will this generate Billed Revenue the AE gets quota credit for?

If any answer is no, it's not an opp yet.

## Red Flag Patterns

### Pattern 1: Self-Serve Claim (Scheyden, Mar 2026)

**What happened:** AE (Connor Walker) sent outreach congratulating a merchant already migrating to Shopify. Tried to book meetings over 15 days. Merchant rescheduled once, ghosted a video call. Opp created on day 15, closed-lost 4 days later at $83K. SF reason: "Product - Lost."

**Why it's bad:**
- Merchant was self-migrating — AE gets $0 credit regardless of outcome
- Zero connected calls, 2 merchant replies out of 10 emails
- Opp created after weeks of unanswered outreach, not after a qualifying conversation
- SF loss reason ("Product - Lost") doesn't match reality (no product conversation ever happened)
- Inflates closed-lost count, drags down win rate, wastes Loss Intelligence analysis

**What should have happened:** Outreach stays in Salesloft as prospecting. Opp only created if merchant says "tell me about Plus" or shows interest in an assisted upgrade. If no qualifying conversation after 2-3 attempts, move on.

**Coaching prompt for manager:** "This merchant was already self-migrating. Was there ever a real Plus conversation, or was this aspirational pipeline?"

<!-- 
### Pattern 2: [TBD — next case]
### Pattern 3: [TBD]
-->

## Pipeline Review Questions

When reviewing opps, managers should ask:

- Does this opp have at least one connected call or substantive merchant reply?
- Was the merchant already on a self-serve path?
- Was the opp created before or after a qualifying conversation?
- If opp lifespan is under 7 days — what triggered creation and what changed?
- Does the SF close reason match what actually happened?

## Signals That Warrant Review

- Opp created and closed within 7 days
- Zero recorded calls with 2+ SF-logged calls (calls that never connected)
- Fewer than 2 merchant replies across all channels
- First AE email references merchant already migrating/trialing
- SF loss reason contradicts engagement pattern
- **Compelling event blank** — opp created without a documented reason (query `sales_opportunities.compelling_event`)
- **Reason details empty on closed-lost** — SF shows "Product - Lost" but `reason_details` has no narrative
- **Closed-lost with 60+ signal score** — re-engagement candidate (see signal scoring in `references/smokesignals-signal-scoring.md`)

## Enriched Loss Analysis

When reviewing a closed-lost opp, pull the enriched fields for deeper analysis:

```sql
SELECT o.primary_result_reason, o.secondary_result_reason, o.reason_details,
  o.compelling_event, o.market_segment, o.description, o.next_step
FROM `shopify-dw.sales.sales_opportunities` o
WHERE o.opportunity_id = @opp_id
LIMIT 1
```

**What to check:**
- `reason_details` vs `primary_result_reason` — do they match? ("Product - Lost" but reason_details says "went with competitor" = misclassification)
- `compelling_event` — was there a real trigger, or was this speculative pipeline?
- `description` + `next_step` — any indication of what actually happened?

## UAL Dupe Detection

Before flagging a deal as "bad pipeline," check if the account is a duplicate or already owned by another rep using the Unified Account List (UAL).

**Source**: `sdp-prd-commercial.mart.unified_account_list` + `shopify-dw.raw_salesforce_banff.website__c`

### Quick UAL Lookup

Given a company name and/or domain from the opp, check for existing account ownership:

```sql
SELECT
  COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
  COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
  territory_name,
  COALESCE(domain, domain_sf, domain_3p, domain_1p) AS best_domain,
  account_id AS sf_account_id
FROM `sdp-prd-commercial.mart.unified_account_list`
WHERE LOWER(COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p)) LIKE LOWER(@search_name)
   OR LOWER(COALESCE(domain, domain_sf, domain_3p, domain_1p))
      LIKE CONCAT('%', LOWER(@search_domain), '%')
LIMIT 10
```

**Domain normalization** — strip protocol, www, path:
```sql
LOWER(REGEXP_REPLACE(IFNULL(domain, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3'))
```

### Dupe Hygiene Signals

When UAL returns results, check:
- **Same account, different owner** → potential territory violation or rep poaching
- **Same domain, different account** → duplicate account in Salesforce (merge needed)
- **Account exists but opp owner ≠ account owner** → crediting mismatch
- **Multiple UAL matches for same domain** → account consolidation issue

### Pattern: Duplicate Account Opp
**Red flag:** Opp created on an account that already exists under a different rep. The second rep may not know the account is already owned. Run UAL check before assessing the opp itself — the issue may be account dedup, not pipeline quality.

## Error Handling

| Scenario | Action |
|----------|--------|
| Opp ID not found in Salesforce | Check for typos. Try searching by merchant name. If still nothing: "Opp may have been deleted or merged." |
| UAL returns multiple matches for same domain | Report all matches with owners. Flag: "Multiple UAL entries — likely account dedup needed before assessing opp hygiene." |
| Enriched fields (reason_details, compelling_event) are all NULL | Flag: "Critical fields empty — this opp has poor data hygiene. Cannot fully assess without reason_details. Recommend manager follow up with rep." |
| User asks to assess an open opp (not closed-lost) | Adjust assessment: "Assessing open opp for red flags. Patterns are less conclusive on active deals — some signals only appear at close." |
| Pattern doesn't match any known case | Describe the signals you see. Say: "No matching pattern in the library yet. If this proves to be a recurring issue, I'll add it as a new pattern." |

## Output Format

Shape output based on hygiene verdict:

### ✅ Clean Pipeline
```
**Opp Hygiene: ✅ CLEAN**
- Qualifying conversation: {evidence}
- Activity signals: {count} activities, last {date}
- No pattern matches.
Summary: Legitimate opportunity. No action needed.
```

### 🟡 Suspect — Needs Review
```
**Opp Hygiene: 🟡 SUSPECT — {pattern name}**
- Pattern match: {which pattern and why}
- Evidence: {specific data points}
- Mitigating factors: {anything that suggests it might be legit}
Coaching question: "{one question for the manager to ask the rep}"
Recommendation: Manager should review with rep before counting in pipeline.
```

### 🔴 Bad Pipeline — Remove or Reclassify
```
**Opp Hygiene: 🔴 BAD PIPELINE — {pattern name}**
- Pattern match: {which pattern} (confidence: {high/medium})
- Evidence: {specific data points — activity gaps, self-serve signals, etc.}
- Impact: ${amount} should not be in pipeline
Coaching question: "{question that helps the rep understand why}"
Recommendation: Remove from pipeline. {Additional guidance based on pattern.}
```

### Classification Taxonomy
| Verdict | Criteria | Action |
|---------|----------|--------|
| ✅ Clean | Two-way conversation verified, activity trail present, creditable revenue path | Count in pipeline |
| 🟡 Suspect | Missing one criterion OR matches a pattern partially | Manager reviews before counting |
| 🔴 Bad Pipeline | Matches known bad pattern OR fails 2+ criteria | Remove from pipeline |

### Conditional Sections (include when relevant)
- **UAL Check Results** — when account ownership is in question
- **Enriched Loss Analysis** — when opp is closed-lost and has loss fields populated
- **Activity Timeline** — when activity gap pattern detected

## Self-Learning: Adding New Patterns

When you encounter a novel bad-pipeline case that doesn't match existing patterns:

1. **Document the case**: Merchant name, opp details, what made it suspect
2. **Extract the pattern**: What signals would identify similar opps? (activity count, timeline, SF reason accuracy)
3. **Add to this skill**: Create a new "Pattern N" section following the existing format:
   ```
   ### Pattern N: {Name} ({example merchant}, {date})
   **What happened:** {narrative}
   **Why it's bad:** {bullets}
   **Red flags (check for):** {checklist}
   **SF accuracy:** {assessment}
   ```
4. **Add detection query** (if applicable): SQL that identifies similar opps
5. **Update the error handling table** if the new pattern revealed an ambiguous scenario

Current patterns: Self-Serve Claim, Premature Creation, Ghost Pipeline, Credit Capture.
New patterns are added as they're discovered through Loss Intelligence and pipeline reviews.

## Integration

- **Loss Intelligence** flags deals → assess here for opp hygiene → add new patterns
- **Sales Call Coach** evaluates call quality → this skill evaluates whether the opp should exist at all
- **Diana Dashboard** metrics are only as clean as the pipeline feeding them
- **UAL Reference** — full query with fuzzy scoring: see `references/company-lookup-ual-query.md`
