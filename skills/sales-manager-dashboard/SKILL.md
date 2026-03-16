---
name: sales-manager-dashboard
description: Build and deploy a personalized Sales Org Dashboard on Quick for any Shopify sales manager. Generates a live BigQuery-powered dashboard with opportunity pipeline, closed won/lost analysis, PBR (Projected Billed Revenue), activity engagement tiers, manager-level filtering, AI chat assistant, 4-tier AI Loss Intelligence (verified transcript matching with confidence scoring for closed-lost opps), and time period toggles. Use when asked to "build a dashboard for [manager name]", "create a sales dashboard", "make a pipeline dashboard", or when a sales leader wants visibility into their org's Salesforce data.
---

# Sales Manager Dashboard Builder

Build a personalized Quick site dashboard for any Shopify sales manager showing their org's Salesforce pipeline, closed won/lost analysis, PBR alignment, activity engagement, AI-powered Q&A, and AI Loss Intelligence — all backed by live BigQuery data.

**Three modes:** New Build | Update Existing | Clone for Different Manager

**What this does NOT do:**
- Does NOT modify Salesforce data — dashboard is read-only (BigQuery)
- Does NOT support real-time streaming — data refreshes on page load
- Does NOT forecast revenue — shows actuals, PBR, and attainment vs quota only
- Does NOT replace Salesforce reports — complements with AI Loss Intelligence + engagement tiers
- Does NOT auto-update when reps change teams — requires manual MANAGERS update + redeploy

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Verify org tree, test queries, validate data access | Ask user for org tree manually; deploy without pre-verification |
| `vault_search` | Look up manager/team info for org tree discovery | Use BigQuery Option B or ask user directly (Option C) |
| `bash` | File operations, Quick CLI deployment, template copying | Guide user through manual steps |
| `write` / `edit` | Customize dashboard template (MANAGERS, ALLOWED_USERS, etc.) | Provide the changes as instructions for manual editing |

## Reference Implementation

The Diana Gates dashboard is the reference: `/Users/venkat/Documents/Cursor project_Sales process site/diana-dashboard/index.html`

Live: `diana-dashboard.quick.shopify.io` (v2.5.2) — Copy this file as the starting template for any new manager dashboard.

## Workflow

### Step 0: What Does the User Have?

```
├── User provides manager name only?
│   ├── Try Vault first (fastest for org tree) → Got team? → Step 1 done
│   ├── Vault fails/unavailable? → Try BigQuery (more reliable) → Got results? → Step 1 done
│   └── BigQuery fails? → Ask user: "Please provide the list of managers and their AEs"
│
├── User provides manager + rep list?
│   → Skip Step 1 discovery, go directly to Step 2 (create directory)
│
├── User provides an existing dashboard to clone for another manager?
│   → Copy existing → update MANAGERS/ALLOWED_USERS → Step 4 (verify) → Step 5 (deploy)
│
└── User asks to UPDATE an existing dashboard (not create new)?
    → Identify what changed → edit in place → redeploy
```

### 1. Identify the Manager's Org Tree

**Try in order until one works:**

**Option A — Vault API** (fastest, try first):
```bash
agent-vault search-users "Diana Gates"
agent-vault get-team <team-id>
```
*If Vault returns partial data (some reps missing), proceed with what you have and note gaps.*

**Option B — BigQuery** (fallback, more reliable for full hierarchy):
```sql
SELECT u.name, u.title, m.name as manager_name
FROM `shopify-dw.base.base__salesforce_banff_users` u
LEFT JOIN `shopify-dw.base.base__salesforce_banff_users` m ON u.manager_id = m.user_id
WHERE m.name = 'TARGET MANAGER NAME' AND u.is_active = TRUE
ORDER BY u.name
```
**Interpret**: If 0 rows, name may not match exactly (try LIKE '%Gates%'). If < 3 reps, manager may have sub-managers — query one level deeper.

**Option C — Ask the requester** for a list of their direct reports and AEs. This is fastest and most accurate when available.

Build the `MANAGERS` object mapping each manager to their rep array:
```javascript
const MANAGERS = {
  'Manager Name': ['Rep 1', 'Rep 2', ...],
};
```

### 2. Create the Dashboard Directory

```bash
mkdir -p /Users/venkat/Documents/Cursor\ project_Sales\ process\ site/<manager-name>-dashboard
cp /Users/venkat/Documents/Cursor\ project_Sales\ process\ site/diana-dashboard/index.html \
   /Users/venkat/Documents/Cursor\ project_Sales\ process\ site/<manager-name>-dashboard/index.html
```

### 3. Customize the Template

Replace these in the copied `index.html`:

| Find | Replace With |
|---|---|
| `Diana Gates` | Manager's full name |
| `diana-dashboard` | New subdomain name |
| `MANAGERS` object | New manager→reps mapping |
| `ALL_REPS` array | All reps in the new org |
| `NAME_TO_MANAGER` | Regenerated reverse lookup |
| `ALLOWED_USERS` | New allowlist of emails |
| `diana.gates@shopify.com` | Manager's email |
| Title tag, header text | Updated names |

### 4. Verify Data Access

Test these queries work for the new org (replace names):

```sql
-- Verify opp count
SELECT COUNT(*) FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
JOIN `shopify-dw.base.base__salesforce_banff_users` u ON o.owner_id = u.user_id
WHERE u.name IN ('Rep1', 'Rep2') AND o.is_deleted = FALSE AND DATE(o.created_at) >= '2026-01-01';

-- Verify PBR data
SELECT COUNT(*) FROM `sdp-for-analysts-platform.rev_ops_prod.report_revenue_reporting_sprint_billed_revenue_cohort`
WHERE opportunity_id IN (SELECT opportunity_id FROM ...);

-- Verify attainment data
SELECT full_name, quota, attainment FROM `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events`
WHERE full_name = 'Manager Name' AND metric = 'Billed Revenue';
```

### 5. Deploy

```bash
cd /Users/venkat/Documents/Cursor\ project_Sales\ process\ site/<manager-name>-dashboard
quick deploy . <manager-name>-dashboard
```

Requires interactive terminal confirmation (Y/n).

## Architecture Decisions (DO NOT CHANGE)

These were learned through debugging. Violating them will break the dashboard:

1. **Closed opps filter by `close_date`, open opps by `created_at`** — Matches AMER Performance Dashboard.
2. **PBR only exists for closed-won** — Open/lost always show SF Amount. PBR↔SF$ toggle only affects closed-won.
3. **`quick.dw.querySync()` returns an object** — Access via `result.rows`. Add fallback: `result.rows || result.data || (Array.isArray(result) ? result : [])`.
4. **BigQuery dates return as objects** — `{value: "2026-01-15"}`. Use `parseDate()` helper.
5. **OAuth scopes once at init** — Don't call per-query; causes re-auth prompts.
6. **Manager mapping hardcoded** — No API for flat mapping. Hardcode `MANAGERS` object.
7. **Closed opps get all-time activity** — Time-period filter determines which opps appear, not what activity counts toward them. Open opps still time-filtered.
8. **Engagement considers SF + SL signals** — `totalSignals = acts + slCalls`; only `totalSignals === 0` shows "No Activity".
9. **Sidequick AI uses `claude-opus-4-5`** — Highest in Shopify proxy.
10. **Hide Sidequick bubble via size-based CSS** — Not position-based (breaks chat panel).
11. **Loss Analysis is on-demand** — Each "🔍 Analyze" click triggers 1 BQ query + 1 `quick.ai.askWithSystem()`, cached per session.
12. **HTML escape all AI output** — `escHtml()` on every piece of AI/transcript text.

## 4-Tier Transcript Matching (DO NOT CHANGE)

The Loss Intelligence feature (v2.6.0) fetches call transcripts AND email exchanges in parallel, sends both to Claude for a multi-source timeline narrative. Uses 4 tiers for transcript matching and date-scoped email queries from `raw_salesforce_banff.task`.

### Main Query SL Counts (Tier 1 + Tier 2)

The main BQ query uses Tier 1 + Tier 2 combined for the SL call count column and engagement tiers:

```
sl_t1: sales_calls_to_opportunity_matching → direct opp link
sl_acct_calls → sl_t2: attendee email → salesloft_people → salesloft_accounts.crm_id = opp account_id
sl_calls: UNION ALL of t1 + t2, COUNT(DISTINCT conversation_id)
```

### On-Demand AI Analysis (All 4 Tiers + Emails)

Two parallel fetches: `fetchOppTranscripts(opp)` + `fetchOppEmails(opp)`

| Tier | Confidence | Method | Date Scope | Batch? |
|---|---|---|---|---|
| **1 — Verified** | 100 | `sales_calls_to_opportunity_matching.event_id` = conversation_id | None (opp-linked = always relevant) | ✅ |
| **2 — Account-verified** | 85 | Attendee email → `salesloft_people` → `salesloft_accounts.crm_id` = opp's `account_id` | **created-60d → close+7d** | ✅ |
| **3 — Contact-matched** | 70 | Attendee full name (exact) → `salesloft_people` → same account chain | **created-60d → close+7d** | ❌ AI only |
| **4 — Fuzzy-scored** | 55-100 | Multi-signal scoring with AND gate | **created-60d → close+7d** | ❌ AI only |

**Date scoping (created-60d → close+7d) is critical (hard-won):**
- Without it, Tier 3 common-name matches pulled calls from unrelated companies (PepWear's "Matthew Miller" matched Granite America, Plateau Metal Sales calls from 2023-2024 — 6 false positives removed)
- Without it, Tier 2 account matches pulled calls from prior deal cycles (Ariela had 2 years of history bleeding in)
- 60-day lookback captures pre-opp SDR prospecting (cadences run 4-8 weeks); 7-day post-close buffer catches wrap-up calls
- Tier 1 is NOT date-scoped: direct opp links are always correct by definition

### Email Data Source (`fetchOppEmails`)

Queries `shopify-dw.raw_salesforce_banff.task`:
- **Opp-linked** (`WhatId = oppId`): Always included, directly relevant
- **Account-linked** (`AccountId`): Date-scoped **created-60d → close** (same rationale as transcripts)
- **Deduplication**: Same subject + same date = 1 row (kills blast emails sent to 12 contacts)
- **Caps**: 25 merchant replies (`Reply:` prefix) + 10 Shopify outbound (`Email:` prefix)
- **Cleaning**: Salesloft URLs stripped from body, body truncated to 500 chars
- `ActivityDate` is TIMESTAMP — use `DATE(ActivityDate)` for date comparisons

### Tier 4 Scoring (max 100 points)

| Signal | Points | Detail |
|---|---|---|
| AE on call | 30 | Opp owner name in internal attendees |
| Date in range | 25 | Call between (created - 60d) and (close + 7d) |
| Name keywords | 25 | Opp name + account name keywords in title/summary |
| Product match | 15 | `primary_product_interest` → call vocabulary |
| Has external | 5 | Non-empty external participant |

**Critical Tier 4 rules:**
- **AND gate**: Requires BOTH AE on call AND at least one **name** keyword (product alone too generic — "plus" matches every call)
- **Threshold**: ≥60 to qualify
- **Hard cap**: Max 10 results per opp
- **Word boundaries**: Single-word keywords use `REGEXP_CONTAINS(text, r'\bword\b')` NOT `LIKE '%word%'` to prevent substring false positives ("maine" ≠ "remained")
- **Phrase + word matching**: `extractNameKeywords()` produces multi-word phrases ("paddle palace tennis") AND individual words ("paddle", "palace"). Phrases use LIKE (already precise).
- **Stop words**: plus, retail, payments, shopify, table, group, global, digital, media, solutions, services, brands, online, store, company, enterprise, and, for, with, new, upgrade

### AI Prompt Requirements

The Loss Intelligence system prompt requires:
- **Full names with roles** for every person: "James Crafa (SE)", not just "James"
- **Role identification**: AE, SE, SDR, Manager for Shopify staff; company + title for external
- Call data labels: AE marked "(AE, deal owner)", others "(Shopify)", external "(prospect/merchant — Account Name)"
- Email labels: `📩 MERCHANT REPLY` for Reply: prefix, `📤 SHOPIFY EMAIL` for Email: prefix
- AI receives match tier + confidence per transcript to weight verified over fuzzy
- **Timeline narrative**: Chronological dated entries with phases (Pre-opp Prospecting, Discovery, Evaluation, Turning Point, etc.)
- **Real sales cycle detection**: Compare earliest email/call to opp created date; report gap if pre-opp activity exists
- **Key people**: Name, role, stance (Champion/Neutral/Blocker/Decision-maker)
- **Transcript coverage gap**: When recorded transcripts < SF-logged calls, AI warned to factor into confidence
- **Date guardrails**: "Do NOT include events after close date"; calendar invites past close = "scheduled but never happened"
- Structured JSON response: `real_reason`, `root_cause`, `sf_reason_accurate`, `sf_reason_gap`, `confidence`, `real_sales_cycle{}`, `timeline[]`, `key_people[]`, `evidence[]`, `preventable`, `recoverable`, `coaching_signal`, `pattern_flag`

### Confidence Badges in UI

| Tier | Badge |
|---|---|
| verified | 🟢 `✓ Verified` |
| account-verified | 🔵 `✓ Account` |
| contact-matched | 🔵 `≈ Contact` |
| fuzzy-scored | 🟡 `⚡ Scored N` |

## Key BigQuery Tables

### Core Dashboard Tables

| Table | Purpose |
|---|---|
| `shopify-dw.base.base__salesforce_banff_opportunities` | Opportunity data |
| `shopify-dw.base.base__salesforce_banff_accounts` | Account names |
| `shopify-dw.base.base__salesforce_banff_users` | SF user lookup |
| `sdp-for-analysts-platform.rev_ops_prod.salesforce_activity` | Activity signals |
| `sdp-for-analysts-platform.rev_ops_prod.report_revenue_reporting_sprint_billed_revenue_cohort` | PBR at opp grain |
| `sdp-for-analysts-platform.rev_ops_prod.RPI_base_attainment_with_billed_events` | Quota + attainment |

### Salesloft / Loss Intelligence Tables

| Table | Purpose | Key Join |
|---|---|---|
| `shopify-dw.intermediate.sales_calls_to_opportunity_matching` | Opp → call bridge (Tier 1) | `event_id` → `conversation_id` |
| `shopify-dw.base.base__salesloft_conversations_extensive` | Transcripts, summaries, attendees | `conversation_id` |
| `shopify-dw.base.base__salesloft_people` | Person records with CRM links (Tier 2/3) | `account.id`, `email_address` |
| `shopify-dw.base.base__salesloft_accounts` | Account records with SF mapping (Tier 2/3) | `crm_id` = SF `account_id` |
| `shopify-dw.raw_salesforce_banff.task` | SDR notes, email bodies | `AccountId` (not always `WhatId`) |

The `base__salesloft_conversations_extensive` key fields:
- `summary.text` — AI-generated call summary (200-500 words)
- `attendees` — REPEATED RECORD: `full_name`, `email`, `is_internal`, `percent_talk_time`
- `key_moments` — structured key moments with categories
- `meddpicc` — MEDDPICC sales methodology data
- `account.id` — Salesloft account ID (NOT Salesforce — join through `salesloft_accounts.crm_id`)

## Output Format

Respond with the literal template matching the request type. Fill in the `{placeholders}`.

### New Dashboard Build → Use this template:
```markdown
## 📊 Dashboard Build — {manager_name}

### Org Tree
| Manager | AEs |
|---------|-----|
| {mgr1_name} | {rep1}, {rep2}, {rep3} |
| {mgr2_name} | {rep4}, {rep5} |
**Total:** {N} managers, {M} AEs

### Data Verification
| Table | Status | Result |
|-------|--------|--------|
| Opportunities | {✅/❌} | {N} opps found for org |
| PBR (Billed Revenue) | {✅/❌} | Data for {N} closed-won deals |
| Attainment | {✅/❌} | {manager_name} found in RPI table |
| Salesloft Transcripts | {✅/❌} | {N} calls in last 90 days |

{IF any ❌:}
### ⚠️ Data Gaps
- {table}: {what's missing + how to fix}
- Features degraded: {list of dashboard features that won't work}

### Customization Applied
- MANAGERS: {N} entries updated
- ALLOWED_USERS: [{emails}]
- AI System Prompt: Updated with {manager_name} context

### Deployed
🔗 **{name}-dashboard.quick.shopify.io**
Share with {manager_name}: {url}
```

### Dashboard Update → Use this template:
```markdown
## 🔄 Dashboard Update — {dashboard_name}
**Change:** {what changed}
**Verification:** {confirmation it works}
**Redeployed:** ✅ Same URL, v{version}
```

### Dashboard Clone → Use "New Dashboard Build" template, adding:
```markdown
### Source Dashboard
Cloned from: {source}-dashboard.quick.shopify.io
Changes from source: {diff summary}
```

## Error Handling

| Scenario | Action |
|----------|--------|
| BigQuery access denied (403) on `sdp-for-analysts-platform` tables | Dashboard will have NO PBR data, NO attainment. Tell user: "PBR and attainment require `sdp-for-analysts-platform` access. Request via #help-data-platform." Display SF Amount only. |
| Manager not found in Salesforce `banff_users` | Try variations: "Diana Gates" → "Diana" + "Gates" separately. If still not found: "Manager not in Salesforce user table. Provide their Salesforce User ID or ask them for their team list." |
| Org tree is incomplete (some reps missing) | Deploy with known reps. Add note: "Dashboard shows {N} reps. If reps are missing, update the MANAGERS object and redeploy." |
| Salesloft transcript tables return 0 for a closed-lost opp | Loss Intelligence will show "No transcripts found." This is expected for opps with no recorded calls. Display email data only if available. |
| `quick deploy` fails | Check: (1) Are you in the right directory? (2) Is `index.html` present? (3) Run `quick auth` if token expired. Common: deploy from parent dir instead of site dir. |
| AI API (claude-opus-4-5) times out during Loss Analysis | Show error: "AI analysis timed out. Try again — transcript may be very long." Consider reducing max transcripts from 8 to 5 for this opp. |
| Dashboard loads but shows no data | Check browser console for BQ errors. Common causes: (1) OAuth scope not granted (user needs to authorize BQ access on first load), (2) ALLOWED_USERS doesn't include the viewer's email, (3) rep names don't match Salesforce exactly (case-sensitive). |
| Manager has 50+ AEs (very large org) | Main BQ query may timeout. Split into sub-queries by manager tier. Consider limiting initial load to current quarter only. |

## Checklist for New Dashboard

- [ ] Org tree mapped (managers + all AEs)
- [ ] `MANAGERS`, `ALL_REPS`, `NAME_TO_MANAGER` updated
- [ ] `ALLOWED_USERS` set (manager email + venkat.iyer@shopify.com)
- [ ] Title, headers, greeting updated with manager name
- [ ] BigQuery access verified (opps, activity, PBR, attainment)
- [ ] Attainment query updated for new manager's name
- [ ] AI system prompt updated with new manager context
- [ ] Loss Analysis "🔍 Analyze" buttons visible in Closed Lost table
- [ ] Loss Analysis tested: click button → transcripts + emails found → AI timeline narrative renders with full names + roles
- [ ] Real sales cycle callout appears when pre-opp prospecting detected
- [ ] Transcript coverage gap shown when recorded calls < SF-logged calls ("1 Recorded Call Transcript (of 31 SF-logged calls)")
- [ ] Key People bar renders with stance icons (Champion/Blocker/Decision-maker)
- [ ] Timeline renders with color-coded phase dots and dated entries
- [ ] Confidence badges visible on matched transcripts (verified/account/contact/scored)
- [ ] Source footer shows both call transcripts and email counts
- [ ] Deployed and tested at `<name>-dashboard.quick.shopify.io`
- [ ] Manager given the URL + confirmed data looks right

## Time Estimate

~30 minutes if org tree is provided, ~1 hour if discovered via BigQuery/Vault.
