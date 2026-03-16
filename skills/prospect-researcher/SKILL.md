---
name: prospect-researcher
description: Research a net-new prospect by checking internal ownership first (UAL + Salesforce), then running external intelligence (web, financials, industry). Use when asked to "research [company]", "who is [prospect]", "prep for net-new meeting", "prospect intel", "is this account taken", or when meeting-prep finds no internal data for an upcoming external meeting. Works for AEs, SEs, SDRs doing outbound or preparing for first conversations.
---

# Prospect Researcher

Research a prospect by first checking if Shopify already knows them (UAL + Salesforce), then enriching with external intelligence. **Always check ownership before external research** — avoids stepping on existing accounts.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | UAL ownership check, enriched account context from `sales_accounts_v1`, shop milestones | ⚠️ Critical: warn user "Cannot verify ownership." Proceed with external only. Add "UNVERIFIED" banner to brief. |
| `perplexity_search` | Company overview, industry context, financial signals, decision-makers | Fall back to `web_search`. If both fail: note "External intel limited — brief based on internal data only." |
| `web_search` | BuiltWith platform detection, SEC filings, job postings, news | Fall back to `perplexity_search`. For platform detection: check view-source of prospect's website. |
| `slack_search` | Internal discussions about this prospect/industry | Skip "Internal Context" section. Note: "No Slack history checked." |
| `vault_search` | Team assignments, territory lookups, relevant playbooks | Skip territory context. Use BQ territory data instead. |

---

## Workflow

### Step 0: UAL Ownership Check + Data Integrity (ALWAYS FIRST)

Before any external research, check the Unified Account List for existing ownership. If a UAL record is found, run `data-integrity-check` on the account_id — if confidence is LOW (duplicate accounts, null region/service_model, inactive territory owner), prepend ⚠️ warnings to your output and note which findings may be unreliable.

```sql
WITH ual_base AS (
  SELECT
    COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
    COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
    territory_name,
    COALESCE(domain, domain_sf, domain_3p, domain_1p) AS best_domain,
    account_id AS sf_account_id,
    LOWER(REGEXP_REPLACE(IFNULL(COALESCE(domain, domain_sf, domain_3p, domain_1p), ''),
      r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS normalized_domain
  FROM `sdp-prd-commercial.mart.unified_account_list`
  WHERE COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) IS NOT NULL
)
SELECT company_name, owner, territory_name, best_domain, sf_account_id
FROM ual_base
WHERE LOWER(company_name) LIKE CONCAT('%', LOWER(@search_name), '%')
   OR normalized_domain LIKE CONCAT('%', LOWER(@search_domain), '%')
ORDER BY
  CASE WHEN LOWER(company_name) = LOWER(@search_name) THEN 1
       WHEN LOWER(company_name) LIKE CONCAT(LOWER(@search_name), '%') THEN 2
       ELSE 3 END,
  CASE WHEN normalized_domain = LOWER(@search_domain) THEN 1 ELSE 2 END
LIMIT 10
```

Also check SF website records for shop ID resolution:

```sql
SELECT a.Name, u.Name AS owner, a.Territory_Name__c, w.Domain__c, w.Shop_Id__c, a.Id
FROM `shopify-dw.raw_salesforce_banff.website__c` w
JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY _sdc_extracted_at DESC) rn
      FROM `shopify-dw.raw_salesforce_banff.account` WHERE IsDeleted = FALSE) a
  ON w.Account__c = a.Id AND a.rn = 1
LEFT JOIN (SELECT Id, Name, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY _sdc_extracted_at DESC) rn
           FROM `shopify-dw.raw_salesforce_banff.user`) u
  ON a.OwnerId = u.Id AND u.rn = 1
WHERE LOWER(w.Domain__c) LIKE CONCAT('%', LOWER(@search_domain), '%')
  AND w.IsDeleted IS FALSE
LIMIT 5
```

**Decision tree after UAL check:**

| UAL Result | Action |
|---|---|
| **Account found, has owner** | ⚠️ STOP — tell user "Account owned by [Owner] in [Territory]. Check before proceeding." |
| **Account found, no owner** | Proceed with research, note unassigned account |
| **No match** | ✅ Green light — proceed with full external research |
| **Multiple fuzzy matches** | Show matches, ask user to confirm none are the target |

### Step 0.5: Enriched Internal Context (after UAL, before external)

If UAL found a match (or if you have an SF Account ID), pull enriched account context. This eliminates redundant external research — we already know industry, revenue, platform, and more.

```sql
-- Enriched account context (34 fields not in base tables)
SELECT a.name, a.industry, a.annual_total_revenue_usd AS revenue,
  a.ecomm_platform, a.account_grade, a.account_priority_d2c AS priority,
  a.sales_lifecycle_stage, a.plus_status, a.number_of_employees,
  a.domain_clean, a.primary_shop_id, a.primary_contact_email,
  a.merchant_success_manager, a.territory_name, a.territory_segment,
  a.account_owner, a.account_url
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.account_id = @sf_account_id
   OR LOWER(a.domain_clean) LIKE CONCAT('%', LOWER(@search_domain), '%')
LIMIT 5
```

```sql
-- Check for existing Shopify shops (are they already a customer?)
SELECT sam.salesforce_account_id, sam.shop_id,
  ms.event_type, FORMAT_TIMESTAMP('%Y-%m-%d', ms.event_at) AS event_date
FROM `shopify-dw.sales.shop_to_sales_account_mapping` sam
LEFT JOIN `shopify-dw.accounts_and_administration.shop_subscription_milestones` ms
  ON sam.shop_id = ms.shop_id
  AND ms.event_type IN ('free_trial_started', 'paid_trial_shop', 'first_paid_trial_subscription')
  AND ms.event_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
WHERE sam.salesforce_account_id = @sf_account_id
ORDER BY ms.event_at DESC
LIMIT 10
```

**What this tells you (skip researching externally if already known):**
- `ecomm_platform` → current competitor (skip BuiltWith lookup)
- `industry` + `annual_total_revenue_usd` → skip generic company overview
- `sales_lifecycle_stage` + `plus_status` → are they already a customer?
- `primary_shop_id` + milestones → active trial? recent churn?
- `account_grade` + `priority` → is this worth pursuing?

### Step 1: External Company Intelligence

Only proceed here if UAL returned no match (or user confirmed it's safe). **Skip any stream where internal data already answers the question.**

Run research streams — **skip any stream where internal data already has the answer:**

| Stream | Purpose | SKIP IF internal data shows... |
|---|---|---|
| Company Overview | What they do, size, HQ | `industry` + `number_of_employees` + `annual_total_revenue_usd` are populated |
| Ecommerce Presence | Current platform, tech stack | `ecomm_platform` field is populated and recent |
| Industry Context | Market position, competitors, news | Always run (internal data doesn't cover market dynamics) |
| Financial Signals | Revenue, funding, growth | `annual_total_revenue_usd` is populated AND >$0 |
| Decision Makers | C-suite, VP Ecommerce | `primary_contact_email` is populated (still run for additional contacts) |

### Step 2: Shopify Fit Assessment

Based on research, assess fit:

| Signal | Indicator | Score |
|---|---|---|
| Currently on a competitor platform | Migration opportunity | ⭐⭐⭐ |
| Growing ecommerce revenue | Expansion opportunity | ⭐⭐⭐ |
| Multiple brands/storefronts | Plus/Enterprise fit | ⭐⭐⭐ |
| B2B + DTC | B2B on Shopify pitch | ⭐⭐ |
| International expansion | Markets pitch | ⭐⭐ |
| Retail + online | POS pitch | ⭐⭐ |
| Small team, DIY | Self-serve, not sales-assisted | ⭐ |

### Step 3: Discovery Questions

Generate 5-7 discovery questions tailored to THIS prospect:
- Based on their current platform pain points
- Connected to their industry challenges
- Designed to uncover budget, timeline, decision process

### Step 4: Compile Brief

Shape the brief based on UAL result:

**If account is OWNED by another rep** → Short brief only:
```
## ⚠️ Prospect Research: [Company Name]
**Status: Account owned by [Owner] in [Territory].**
Do not proceed without coordinating with the account owner.

### Account Details
- Owner: [Name] | Territory: [Territory] | SF ID: [ID]
- Domain: [domain] | Internal grade: [grade]
```
Omit: Discovery Questions, Talking Points, Key People, Fit Assessment. The user should talk to the owner, not pursue independently.

**If account is UNOWNED or NOT FOUND** → Full brief:
```
## 🔍 Prospect Research: [Company Name]
**Domain:** [domain] | **Industry:** [industry] | **HQ:** [location]

### UAL Status
[✅ No existing account / 🟡 Unowned account found in UAL]

### Internal Context (from sales_accounts_v1) — INCLUDE ONLY IF DATA EXISTS
- **Grade:** [A/B/C/D] | **Priority:** [High/Medium/Low] | **Lifecycle:** [stage]
- **Current platform:** [ecomm_platform] | **Plus status:** [status]
- **Existing shops:** [N shops found / None] | **Trial status:** [active trial / churned / none]
If no internal data: expand Company Snapshot section with more external detail.

### Company Snapshot
- **What they do:** [1-2 sentences]
- **Size:** [employees, revenue range]
- **Current platform:** [source: internal data / BuiltWith / view-source]
- **Key products/brands:** [list]

### Shopify Fit
**Overall:** [Strong / Moderate / Weak] — [one-line reason]
| Signal | Details |
|---|---|
| [Signal] | [Evidence from research, not guesses] |

### Key People
| Name | Role | Why Relevant |
|---|---|---|
| [Name] | [Title] | [Decision-maker / Technical buyer / Champion] |

### Discovery Questions — INCLUDE ONLY IF NO OWNER CONFLICT
1. [Question — based on their specific situation]
2. [Question]

### Talking Points — INCLUDE ONLY IF FIT IS MODERATE OR STRONG
- [Relevant Shopify capability → their specific need]
- [Case study from their industry]

### Sources
- [URL — what was found there]
```

**If BQ was unavailable (UNVERIFIED)** → Add banner at top:
```
⚠️ UNVERIFIED: BigQuery access failed. Could not check UAL ownership.
Verify account ownership manually before outreach.
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| UAL check fails (BQ access denied) | Warn: "⚠️ Could not verify account ownership — proceed with caution." Add banner to brief. NEVER skip mentioning the failure. |
| UAL returns multiple fuzzy matches | Show all matches with owner + domain. Ask: "Do any of these match your target? If yes, they're already in our system." Do NOT auto-dismiss fuzzy matches. |
| Company name matches but domain doesn't (or vice versa) | Report both. "Company name matches '{X}' in UAL but domain doesn't match. Could be: (1) parent/subsidiary, (2) rebranded, (3) different company. Verify with user." |
| Company is very small (< 5 employees, pre-revenue) | Note: "Limited public info — likely self-serve fit, not sales-assisted. If user still wants research, provide what's available but flag: 'This prospect may not justify AE time.'" |
| No web results for company | Ask for: domain, industry, or a LinkedIn URL. If still nothing: "Company has minimal web presence — may be pre-launch, private, or B2B-only." |
| Internal data conflicts with external (e.g., sales_accounts_v1 says "Magento" but website runs Shopify) | Report BOTH: "Internal records show Magento, but live site appears to run Shopify. Data may be stale. Recommend verifying current platform before outreach." |
| Domain resolves to a parked/dead site | Flag: "Domain {x} appears parked/inactive. Company may have rebranded, been acquired, or shut down. Check for recent news." |
| `sales_accounts_v1` shows `account_grade = D` or `priority = Low` | Include in brief but flag: "Account graded D/Low priority in Salesforce. Discuss with manager before investing significant time." |
| User provides a person's name instead of a company | Search for the person first (LinkedIn, Slack). Extract their company, then research the company. Note: "Researching {Person's} company: {Company}." |
| Company is a Shopify partner/agency, not a merchant | Flag immediately: "This appears to be a Shopify partner/agency, not a merchant prospect. Partner relationships are managed differently — check with Partner team." |

---

## Anti-Patterns

- **Never skip the UAL check** — this is the #1 rule
- **Don't research accounts you can't sell to** — if UAL shows another rep owns it, stop
- **Don't present internal Shopify data externally** — this brief is for internal prep only
- **Don't assume platform from domain alone** — verify with BuiltWith or source code inspection
