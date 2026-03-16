---
name: product-gap-tracker
description: Draft and track Salesforce product feedback when platform limitations or feature gaps are identified. De-duplicates against prior submissions, formats for copy-paste into Salesforce, and connects gaps to merchant impact and deal outcomes. Use when a limitation is discovered, a feature gap blocks a deal, user says "draft product feedback", "log a product gap", "feature request for [X]", "this is a gap", or when Loss Intelligence analysis reveals a product-driven loss reason. Works for AEs, SEs, CSMs, and Rev Ops tracking patterns.
---

# Product Gap Tracker

Draft product feedback for Salesforce when Shopify limitations or feature gaps are identified. Connects gaps to real deal impact.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Pull Salesforce opp context, Loss Intelligence data for pattern detection | Draft feedback without deal specifics. Note: "Add opportunity ID and deal context before submitting." |
| `slack_search` | Check #product-feedback, #checkout-feedback for existing reports of this gap | Skip duplicate check. Note: "⚠️ Unable to verify if previously reported. Search Slack manually before submitting." |
| `vault_search` | Check for existing GSD projects addressing this gap | Skip. Note: "Couldn't verify if this is on the roadmap. Check with PM before submitting." |
| `perplexity_search` | Verify competitor claim about the capability gap | Use domain knowledge. Flag: "Competitor claim unverified — do NOT include in feedback without confirmation." |

**This skill works with zero tools** — the minimum output is a formatted Salesforce product feedback entry the user can copy-paste.

---

## When to Trigger

1. **Explicit:** User says "draft product feedback", "log a gap", "feature request"
2. **Discovery:** A platform limitation surfaces during research or solutioning
3. **Loss analysis:** Loss Intelligence AI identifies a product-driven loss reason (e.g., `root_cause` mentions missing feature, `pattern_flag` references product gap)
4. **Competitive:** Competitor has a capability Shopify lacks that's blocking a deal

---

## Workflow

### Step 1: Identify the Gap

Extract from context:
- **What's missing:** Specific feature, capability, or behavior
- **Where it matters:** Which workflow, API, or surface area
- **Who it blocks:** Merchant name, deal size, segment

### Step 2: Check for Duplicates

Before drafting, search for existing feedback:

1. **Vault** — Search for GSD projects or product feedback matching the gap
2. **Slack** — Search #product-feedback, #help-[team], or relevant channels
3. **Salesforce** — Check if the same merchant already has product feedback logged

If duplicate found → reference it instead of creating new. Add the new merchant as another data point.

### Step 3: Assess Impact

| Signal | Source | Question |
|---|---|---|
| **Deal impact** | Salesforce | Did we lose a deal over this? How many deals? Total $ lost? |
| **Frequency** | Loss Intelligence / Salesforce | How often does this come up in lost deals? |
| **Workaround** | Platform knowledge | Is there a native, app, or custom workaround? |
| **Competitive** | Battle cards / Competitive intel | Do competitors have this? Is it a differentiator? |
| **Roadmap** | Vault GSD projects | Is this already planned? What phase? |

### Step 4: Draft Feedback

**Copy-paste-ready format for Salesforce:**

```
**Title:** [Feature Area] — [Brief description of gap]

**Description:**
[Context]: [What the merchant needs and why]
[Limitation]: [What Shopify currently does/doesn't do]
[Impact]: [How this affected the deal — be specific with $ and timeline]
[Workaround]: [Current alternatives, if any, and their limitations]

**Merchant:** [Merchant Name] ([Plan Tier] — [Segment])
**Deal Value:** $[Amount] | **Stage:** [Stage] | **Outcome:** [Won/Lost/Open]
**Competitor Mentioned:** [If applicable — which competitor has this]

**Additional Data Points:**
- [Other merchants who hit this same gap — from Loss Intelligence or Salesforce search]
- [Frequency: "X of Y closed-lost deals in [segment] mention this"]

**Source:** [Discovery call / Loss Intelligence analysis / Competitive research / Demo feedback]
```

### Step 5: Connect to Patterns (if Loss Intelligence data available)

When triggered from Loss Intelligence or when `agent-data` is available:

```sql
-- Find other deals lost to the same product gap
SELECT o.name, o.amount_usd, o.close_date, o.primary_result_reason,
       u.name as owner_name
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
JOIN `shopify-dw.base.base__salesforce_banff_users` u ON o.owner_id = u.user_id
WHERE o.stage_name = 'Closed Lost'
  AND o.close_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
  AND (LOWER(o.primary_result_reason) LIKE '%[gap_keyword]%'
       OR LOWER(o.name) LIKE '%[product_area]%')
ORDER BY o.amount_usd DESC
LIMIT 10
```

Add pattern data to the feedback:

```
**Pattern Analysis:**
In the last 6 months, [N] deals totaling $[X] were lost with reasons mentioning [gap area].
Top affected segments: [Segment breakdown]
Top affected products: [Product breakdown]
```

---

## Tracking Output

After drafting, suggest next steps:

```
📋 Product Feedback Draft Ready

**Gap:** [Title]
**Impact:** $[Total deal value affected] across [N] deals
**Duplicates Found:** [Yes — link / No — new gap]
**Workaround Exists:** [Yes — describe / No]

**Next Steps:**
1. [ ] Copy feedback to Salesforce Product Feedback field
2. [ ] Share in #product-feedback Slack channel (if pattern affects multiple reps)
3. [ ] Link to existing GSD project [if found]: [URL]
4. [ ] Consider drafting a GSD proposal [if gap is systemic and >$500K total impact]
```

---

## Integration with Loss Intelligence

When Loss Intelligence (diana-dashboard or similar) identifies product-related losses:

- `pattern_flag` containing "product" → auto-suggest drafting product feedback
- `root_cause` mentioning specific features → pre-populate the gap description
- `coaching_signal` mentioning "feature gap" → include in the workaround section
- Multiple deals with same `pattern_flag` → aggregate into pattern analysis

---

## Domain Rules — Salesforce Product Feedback

- **Salesforce field**: Product Feedback is submitted via the `Product_Feedback__c` custom object. Key fields: `Feedback_Type__c` (Enhancement / Bug / Missing Capability), `Product_Area__c` (Checkout, Payments, Shipping, Orders, Catalog, etc.), `Impact_Level__c` (Revenue Blocking / Competitive Gap / Nice to Have), `Related_Opportunity__c` (lookup to Opportunity).
- **Product feedback taxonomy**: Use EXACT categories from Salesforce picklist. Do NOT invent categories. Common: "Checkout Flow", "Payment Methods", "Order Management", "International/Markets", "B2B", "Discounts/Promotions", "API/Extensibility", "Admin Experience", "POS".
- **Revenue impact MUST be quantified.** "This feature costs us deals" is weak. "3 deals totaling $2.1M lost in Q1 2026 citing this gap" is actionable. Always pull numbers.
- **Workaround must be honest.** If no workaround exists, say "No workaround." Do NOT suggest fragile hacks that will embarrass the AE in front of the merchant.
- **De-duplicate before submitting.** Same feature requested 5 times = 1 submission with 5 data points. NOT 5 separate submissions.

## Error Handling

| Scenario | Action |
|----------|--------|
| No Salesforce context (no opp ID provided) | Draft feedback without deal specifics. Add placeholder: "Add opportunity ID and deal context before submitting to Salesforce." |
| Vault/Slack unavailable | Skip duplicate check. Flag: "⚠️ Duplicate check skipped — search #product-feedback before submitting." |
| No pattern data (single deal) | Draft single-deal feedback. Still valuable — note: "Pattern analysis unavailable (single data point). If more deals hit this gap, aggregate in a follow-up." |
| Gap is actually a configuration issue, not a product gap | STOP. "This appears to be a configuration/setup issue, not a product gap. Try: [solution]. If it persists, submit a support case instead of product feedback." |
| User conflates "I want this" with "merchants need this" | Challenge: "Is this a merchant need or an internal workflow preference? Product feedback should cite merchant impact. Rephrase in terms of merchant value." |
| Gap already addressed (Vault shows active GSD project) | Report: "This is being actively worked on — GSD #{project_id}: {title}. Consider adding your deal as a data point to the existing project instead of new feedback." |
| Competitor claim is unverifiable | Do NOT include in feedback. "I can't verify that {competitor} has this. Submit feedback based on the merchant's stated need, not the competitor comparison." |
| Multiple deals show same pattern but user only mentions one | Surface the pattern: "I found {N} other closed-lost deals with similar loss reasons. Want me to aggregate into a pattern-based feedback submission? That carries more weight." |
