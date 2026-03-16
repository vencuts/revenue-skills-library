---
name: deal-prioritization
description: Generate a prioritized deal dashboard from Salesforce opportunities and cases with scoring, tier classification, and time allocation recommendations. Use when asked "what should I focus on", "show my priorities", "rank my deals", "deal priority", "pipeline priorities", "where should I spend time", "update my dashboard", or "triage my pipeline". Works for AEs, SEs, CSMs — any revenue role managing a portfolio of deals or accounts.
---

# Deal Prioritization

Generate a unified priority dashboard from Salesforce opportunities and cases with scoring and time allocation guidance.

You are NOT a forecast tool — do NOT predict revenue or close probabilities beyond what Salesforce provides. You are NOT a deal coach — do NOT evaluate discovery quality or call technique (use `sales-call-coach`). You are NOT an opp hygiene checker — do NOT flag self-serve claims or premature creation (use `opp-hygiene`). You RANK deals by priority and ALLOCATE time.

**Key terms (Shopify-specific):**
- **"Billed Revenue"** — not the same as SF Amount. Billed Revenue = actual invoiced revenue post-close. Amount = projected deal value. Prioritization uses Amount (forward-looking), not Billed Revenue (backward-looking).
- **"Compelling event"** — a time-bound reason the merchant MUST decide (contract expiration, peak season, board mandate). Deals with compelling events get +2 urgency. Deals without compelling events are inherently lower priority regardless of size.
- **"Ghost deal"** — open opp with zero activity in 14+ days. Not the same as a stalled deal (stalled = in same stage 30+ days). A ghost deal may have changed stages but has no human interaction.
- **"Account grade"** — UAL-derived A/B/C/D grade reflecting fit scoring. A-grade accounts get priority even at lower deal sizes.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Pull open opps, cases, activity data from `base__salesforce_banff_*` and `salesforce_activity` | Ask user to paste pipeline export (CSV or list of deals). Apply scoring to whatever data provided. |
| `vault_search` | Look up user profile for Salesforce UserId, team context | Ask user for their SF email. Search BQ `banff_users` by email. |
| `slack_search` | Check for deal-related discussions, blockers mentioned in channels | Skip "internal context" for deals. Note: "No Slack context checked." |
| `perplexity_search` | Industry context for deal scoring (market conditions, competitor activity) | Use deal data alone for scoring. Note: "Scoring based on deal attributes only, no external market context." |

**Degraded mode**: If no BQ access AND no user data paste, this skill cannot function. Say: "I need either BigQuery access or a paste of your pipeline data (opp name, amount, stage, close date, product) to prioritize."

---

## Workflow

### Step 0: Route by Role + Validate Data Quality

Before scoring deals, run `data-integrity-check` on the rep's email to verify their worker attributes (region, segment, LOB) are present — missing attributes mean the scoring formula uses wrong segment weights. Also spot-check the top 3 deals for account duplicates — a deal scored HIGH on a duplicated account may be double-counted in pipeline.

```
User identified as...
│
├── AE (Account Executive)
│   → Pull: opps owned + activity + attainment
│   → Score: deal velocity, engagement, close probability
│   → Focus: "What deals will close this quarter?"
│
├── SE (Solutions Engineer)
│   → Pull: opps where SE is assigned (SE_Assigned__c or mention in opp team)
│   → Score: technical complexity, POC status, deal size (SE time allocation)
│   → Focus: "Which technical evaluations need my time?"
│
├── CSM (Customer Success Manager)
│   → Pull: accounts owned + open cases + renewal dates
│   → Score: churn risk, expansion opportunity, case severity
│   → Focus: "Which accounts need attention to protect/grow revenue?"
│
└── Unknown role → Ask: "Are you an AE, SE, or CSM? Scoring dimensions differ by role."
```

### Step 1: Identify User

Determine Salesforce UserId:
- From `personal-config.md` if available
- From Vault profile lookup
- Ask user if neither available

Also determine: current quarter dates, role (from Step 0), team target vs individual quota.

### Step 2: Query Salesforce (Parallel)

**Opportunities:**
```sql
SELECT o.Id, o.Name, o.StageName, o.Amount, o.CloseDate, o.Probability,
       o.Primary_Product_Interest__c, o.Competitor__c,
       o.SE_Next_Steps__c, o.NextStep,
       a.Name as AccountName, a.Industry
FROM Opportunity o
LEFT JOIN Account a ON o.AccountId = a.Id
WHERE o.Id IN (
  SELECT OpportunityId FROM OpportunityTeamMember
  WHERE UserId = '[USER_ID]'
)
AND o.CloseDate >= '[QUARTER_START]'
AND o.CloseDate <= '[QUARTER_END]'
AND o.RecordType.Name = 'Sales'
AND o.IsClosed = FALSE
ORDER BY o.CloseDate ASC
```

**Cases (if CSM/SE with launch responsibilities):**
```sql
SELECT Id, CaseNumber, Subject, Status, Priority,
       Account.Name, CreatedDate, ClosedDate
FROM Case
WHERE OwnerId = '[USER_ID]'
AND RecordType.Name = 'Launch'
AND IsClosed = FALSE
ORDER BY Priority DESC, CreatedDate ASC
```

### Step 3: Calculate Priority Scores

**Formula:** `Priority Score = Revenue Points + (Close Probability × 2) + Urgency Points + Account Quality Points`

**Revenue Points:**

| Deal Size | Points |
|---|---|
| $5M+ | 10 |
| $2M–$5M | 8 |
| $1M–$2M | 6 |
| $500K–$1M | 4 |
| $100K–$500K | 2 |
| < $100K | 1 |

**Close Probability Points (×2):**

| Probability | Points |
|---|---|
| Very High (90%) | 3.6 |
| High (60%) | 2.4 |
| Medium (40%) | 1.6 |
| Low (20%) | 0.8 |
| Very Low (5%) | 0.2 |

Default if null: 0.4 (Medium)

**Account Quality Points** (from `sales_accounts_v1`):

```sql
SELECT a.account_grade, a.account_priority_d2c, a.sales_lifecycle_stage,
  a.ecomm_platform, a.annual_total_revenue_usd
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.account_id = @sf_account_id
```

| Grade | Points | Priority | Points |
|---|---|---|---|
| A | +3 | Critical | +3 |
| B | +2 | High | +2 |
| C | +1 | Medium | +1 |
| D/null | 0 | Low/null | 0 |

Also check for compelling event urgency:
```sql
SELECT compelling_event FROM `shopify-dw.sales.sales_opportunities`
WHERE opportunity_id = @opp_id
```
If `compelling_event` mentions contract renewal, deadline, or migration date → +2 bonus urgency.

**Urgency Points:**

| Timeframe | Points |
|---|---|
| This week (0–7 days) | +4 |
| This month (8–30 days) | +2 |
| Next month (31–60 days) | +1 |
| Later (>60 days) | 0 |

**Score range:** 4–22

### Step 4: Classify Tiers

| Tier | Score | Time Allocation | Action |
|---|---|---|---|
| **Tier 1 — Hot** 🔴 | 15–22 | 60% of time | Daily attention, active engagement |
| **Tier 2 — Warm** 🟡 | 10–14 | 30% of time | Weekly check-ins, strategic nudges |
| **Tier 3 — Watch** 🟢 | 5–9 | 10% of time | Monitor, respond when needed |
| **Pipeline** ⚪ | <5 | Monitor | Track milestones only |

### Step 5: Generate Dashboard

```markdown
# 📊 Priority Dashboard — [Name]
**Generated:** [Timestamp]
**Quarter:** [Q# YYYY] ([start] → [end])
**Role:** [AE/SE/CSM]

---

## ⏱️ Time Allocation This Week

| Tier | Deals | Total Value | Recommended Time |
|---|---|---|---|
| 🔴 Hot | [N] | $[X] | 60% |
| 🟡 Warm | [N] | $[X] | 30% |
| 🟢 Watch | [N] | $[X] | 10% |

**Total Pipeline:** $[X] across [N] deals

---

## 🚨 Needs Attention

- **Closing THIS WEEK:** [Deal names + amounts]
- **Stalled (>30 days in stage):** [Deal names]
- **No activity in 14+ days:** [Deal names]
- **At-risk (competitor mentioned + low probability):** [Deal names]

---

## 🔴 Tier 1 — Hot (Score 12–16)

| Deal | Account | Amount | Close | Stage | Score | Next Step |
|---|---|---|---|---|---|---|
| [Name] | [Account] | $[X] | [Date] | [Stage] | [Score] | [Next step] |

## 🟡 Tier 2 — Warm (Score 8–11)

| Deal | Account | Amount | Close | Stage | Score | Next Step |
|---|---|---|---|---|---|---|
| [Name] | [Account] | $[X] | [Date] | [Stage] | [Score] | [Next step] |

## 🟢 Tier 3 — Watch (Score 4–7)

| Deal | Account | Amount | Close | Stage | Score |
|---|---|---|---|---|---|
| [Name] | [Account] | $[X] | [Date] | [Stage] | [Score] |

---

## 📋 Cases / Launch Queue

| Case | Account | Status | Priority | Created | Notes |
|---|---|---|---|---|---|
| [#] | [Account] | [Status] | [P1/P2/P3] | [Date] | [Brief] |
```

---

## Risk Signals to Flag

| Signal | Detection | Display |
|---|---|---|
| **Stalled deal** | >30 days in same stage | ⚠️ Stalled |
| **No recent activity** | No SF activity in 14+ days | ⚠️ Ghost |
| **Closing soon, low probability** | Close < 14 days AND probability < 40% | ⚠️ At Risk |
| **Competitor mentioned** | Competitor field populated | 🆚 [Competitor] |
| **Large deal, no next steps** | Amount > $500K AND next steps empty | ⚠️ No Plan |
| **Pushed close date** | Close date moved back in last 30 days | 📅 Pushed |

---

## Refresh Cadence

- **Daily:** Tier 1 deals — check for stage changes, new activity
- **Weekly:** Full dashboard refresh — re-score all deals
- **Ad-hoc:** After deal reviews, pipeline calls, or forecast submissions

---

## SE Engagement Thresholds (for AE prioritization)

When reviewing deals for an AE, flag SE engagement requirements alongside priority scores:

| Deal GMV / ARR | SE Required? | Action |
|---|---|---|
| < $3M | No — async only | AE-led, SE available via Slack |
| $3M–$5M | Yes — standard demo | Request SE 48h before demo |
| $5M+ | Yes — custom engagement | Request SE 72–96h out, full handoff brief |
| Commerce Components | Yes — SE-led | SE assigned at opp creation |

Add a **🔧 SE Required** flag to any Tier 1 or Tier 2 deal at $3M+ with no SE assigned.

---

## Output Format

### Standard Dashboard
```
## 📊 Priority Dashboard — [User Name] | [Date]
**Pipeline:** $X across N deals | **Quota attainment:** Y%

### Tier 1 — Focus This Week (X deals, $Y)
| Rank | Deal | Amount | Stage | Close | Score | Key Action |
|------|------|--------|-------|-------|-------|------------|
| 1 | [Name] | $X | [Stage] | [Date] | XX/100 | [Specific next action] |

### Tier 2 — Active Management (X deals, $Y)
[Same table format]

### Tier 3 — Monitor Only (X deals, $Y)
[Same table format]

### 🚨 Stale Deals (no activity > 14 days)
[List with last activity date and recommendation]

### ⏰ Time Allocation
| Activity | Hours/Week | Deals |
|----------|------------|-------|
| Tier 1 focus | X | [list] |
| Tier 2 management | X | [list] |
```

### If User Provides Pasted Data (no BQ)
- Skip activity-based scoring dimensions
- Note: "Scoring excludes engagement/activity signals (no BQ access). Focus on deal attributes: size, stage, close date."
- Still provide tier classification and time allocation

### Conditional Sections
- **SE Required** (only for deals > $3M without SE): Add flag and recommendation
- **Cases** (only if user has open cases): Separate priority section
- **Stale Deals** (only if any have 14+ days no activity): Highlight as risk

## Error Handling

| Scenario | Action |
|----------|--------|
| No Salesforce access (BQ denied) | Ask: "Paste your pipeline data — I need at minimum: deal name, amount, stage, close date." Apply scoring to pasted data. |
| UserId unknown | Search `base__salesforce_banff_users` by email. If multiple matches: "I found {N} users. Which one?" If zero: "Couldn't find you in Salesforce — provide your SF email." |
| No open deals found | Check: (1) correct quarter dates, (2) correct UserId, (3) try expanding to all active opps regardless of quarter. If still nothing: "No open opportunities found. Are you a new AE, or do your deals live under a different Salesforce user?" |
| No cases | Skip cases section silently. Don't mention the absence. |
| Close date in the past for open deals | Flag: "⚠️ {N} deals have close dates in the past but are still open. These need immediate attention — either push the date or close them." |
| Same deal appears in both opps and cases | Consolidate into one row. Note: "This deal has both an opp and a case — cross-reference when planning." |
| User has 50+ open opps | Too many for a single view. Auto-filter to current quarter close dates. Note: "Showing {N} current-quarter deals out of {total}. Run with 'all' to see full pipeline." |
| Scoring data is incomplete (e.g., no activity data) | Score with available dimensions. Note: "Score based on {N}/6 dimensions (missing: engagement, recency)." Reduce confidence in tier assignment. |
| User disagrees with tier assignment | Ask: "What's your gut feeling? If your prioritization differs from the score, tell me what I'm missing." Update scoring context — the user knows things the data doesn't. |

When a new scoring pattern emerges (e.g., deals with a specific compelling event type close faster), add it to the scoring formula and update the Priority Points tables. Scoring evolves with the sales motion.

## Platform Reference Data
Load these files for current Shopify platform data before responding:
