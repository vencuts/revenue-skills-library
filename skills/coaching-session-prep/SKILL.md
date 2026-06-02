---
name: coaching-session-prep
description: Prepare a CS Lead for a 1:1 coaching session with one of their CSMs. Pulls the CSM's portfolio health, call quality scores, goal progress, open action items, at-risk accounts, engagement compliance, and sentiment alerts — then synthesizes a coaching prep card with specific talking points. Use when asked to "prep for my 1:1 with [CSM]", "coaching prep", "prepare for coaching session", "1:1 prep for [name]", "what should I discuss with [CSM]", "coaching agenda", or "review [CSM]'s performance." Built for CS Leads managing 6-10 CSMs; also works for managers and admins reviewing any CSM.
---

# Coaching Session Prep

Prepare a CS Lead for a 1:1 coaching session with a specific CSM — the Monday question: **"What does this CSM need from me this week?"**

You are NOT a meeting-prep tool for external merchant calls (use `meeting-prep`). You are NOT a portfolio triage tool — you surface CSM performance patterns, NOT individual account triage (use `csm-portfolio-triage` for that). You are NOT building the CSM's prep — this is the **Lead's prep** about the CSM. The CSM should prepare their own 1:1 agenda separately.

**[INTERNAL-ONLY]** — coaching content, do not share with the CSM's reports or external stakeholders.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` / `agent-data` | CSM's portfolio accounts, health scores, engagement compliance, activity metrics, NRR pacing | Fallback: ask lead to paste the CSM's portfolio summary from CS Compass Overview. Even a verbal "how's their book?" gives enough for a framework-based coaching prep. |
| `quick-cs-compass` MCP | Coaching sessions (prior 1:1 notes, commitments, topics), goals (active + progress), action items (open + overdue), call scores (dimension breakdown), sentiment alerts, RHS scores | Fallback: ask lead "What did you discuss last time? Any open commitments?" and "How are their calls going?" Build prep from lead's recollection + BQ data. |
| `vault_search` | CSM profile, tenure, team structure | Ask lead directly. Minor impact. |
| `slack_search` | Recent mentions of CSM or their accounts in team channels | Skip Slack section. Note: "No Slack context checked." |

**Graceful degradation**: BQ gives portfolio data. CS Compass Quick.db gives coaching history. Either alone produces a useful prep card. Both together produce the full picture. With neither, use the framework from Stephen Rogan's manager-one-on-one-prep model: structure the conversation around What Changed → Accounts to Discuss → Asks → Development.

---

## Key Domain Vocabulary

- **Coaching Session** — A structured 1:1 between Lead and CSM in CS Compass. Types: `protect` (risk-focused — at-risk accounts, mitigation review), `foundations` (capability-building — product adoption, onboarding accounts, platform skills), `growth` (opportunity-focused — expansion, upsell), `development` (career/skill-focused), `weekly` (regular cadence check-in), `general` (mixed agenda).
- **Call Scoring Dimensions** — 3 dimensions used to evaluate CS calls: Discovery (35%), Value (30%), Accountability (35%). Mapped from SHIFT + MEDDIC frameworks.
- **Engagement Compliance** — Whether the CSM is meeting contact frequency targets for their segment and account priority tiers. Tracked per-account.
- **RHS Tier** — Risk-Health Score: Healthy (score 15+), Atrophying (7-14), At Risk (<7). Measures portfolio trajectory.
- **Sentiment Alert** — CS Compass flags accounts where customer sentiment has shifted negatively based on call analysis and interaction patterns.
- **Weekly Triage** — Metrics tracked per coaching session: meetings_count, warm_calls, no_shows, unique_meetings.
- **Value Engine Quadrant** — ENGINE (high activity + good outcomes), LUCKY (low activity + good outcomes), UNLUCKY (high activity + poor outcomes), PASSENGER (low activity + poor outcomes).

---

## Workflow

### Step 0: Identify the CSM and Context

- **Has CSM name or email?** → Use directly
- **No CSM specified?** → Ask: "Which CSM are you prepping for? Name or email."
- **Lead wants to prep for multiple CSMs?** → Run sequentially, one prep card per CSM. Or suggest: "Want a team overview instead? I can summarize all your CSMs in one view."

Also gather:
- When is the 1:1 scheduled? (affects urgency of prep)
- Any specific topics the lead wants to cover? (adds focus areas to output)

### Step 1: Pull CSM Performance Data

Run in parallel:

**From BigQuery — Portfolio Health Summary:**
```sql
WITH target_accounts AS (
  SELECT sa.account_id, sa.merchant_success_manager AS csm_name,
    sa.merchant_success_manager_email AS csm_email, su.manager_name AS lead_name,
    CASE
      WHEN su.manager_name = 'Megan Schmidling' THEN 'Unicorn'
      WHEN su.manager_name IN ('Nikole Gabriel-Brooks','Aiko Lista','Arnaud Bonnet') THEN 'Mid-Market Scaled'
      WHEN su.manager_name IN ('Jared Frazer','Kasia Mycek') THEN 'Mid-Market Assigned'
      WHEN su.manager_name IN ('Niresan Seevaratnam','Tyler Cuddihey','Amy Franklin') THEN 'Large Accounts'
      ELSE 'N/A' END AS segment
  FROM `shopify-dw.sales.sales_accounts` AS sa
  LEFT JOIN `shopify-dw.sales.sales_users` AS su ON sa.merchant_success_manager_id = su.user_id
  WHERE su.is_active = TRUE AND LOWER(sa.merchant_success_manager_email) = LOWER(@csm_email)
),
target_shop_ids AS (
  SELECT DISTINCT map.shop_id, map.account_id
  FROM `shopify-dw.mart_revenue_data.revenue_shop_salesforce_summary` AS map
  INNER JOIN target_accounts AS t ON map.account_id = t.account_id
),
account_metrics AS (
  SELECT c.account_id, c.gmv_usd_l365d, c.revenue_l12m, c.gmv_growth_yearly AS gmv_growth_yoy, c.banff_risk_level
  FROM `sdp-prd-commercial.mart.copilot_account_attributes` AS c
  INNER JOIN target_accounts AS t ON c.account_id = t.account_id
),
product_adoption AS (
  SELECT csa.account_id,
    MAX(CAST(COALESCE(csa.shopify_payments.adopted_shopify_payments, FALSE) AS INT64)) AS has_payments,
    MAX(CAST(COALESCE(csa.shop_pay.adopted_shop_pay, FALSE) AS INT64)) AS has_shop_pay
  FROM `sdp-prd-commercial.mart.copilot_shop_attributes` AS csa
  INNER JOIN target_shop_ids AS t ON csa.shop_id = t.shop_id
  GROUP BY csa.account_id
),
activity AS (
  SELECT t.account_id,
    DATE_DIFF(CURRENT_DATE(), DATE(MAX(act.date_of_activity)), DAY) AS days_since_activity
  FROM `sdp-for-analysts-platform.rev_ops_prod.report_post_sales_dashboard_activities` AS act
  INNER JOIN `shopify-dw.raw_salesforce_banff.event` AS ev ON act.activity_id = ev.Id
  INNER JOIN target_accounts AS t ON act.account_id = t.account_id
  WHERE DATE(act.date_of_activity) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND (ev.Meeting_No_Show__c IS NULL OR ev.Meeting_No_Show__c = FALSE)
    AND (ev.IsDeleted IS NULL OR ev.IsDeleted = FALSE)
  GROUP BY t.account_id
)
SELECT t.csm_name, t.csm_email, t.segment, t.lead_name, COUNT(*) AS account_count,
  SUM(CASE WHEN am.banff_risk_level IN ('High','Critical') THEN 1 ELSE 0 END) AS at_risk_count,
  ROUND(AVG(am.gmv_usd_l365d), 0) AS avg_gmv,
  SUM(CASE WHEN COALESCE(act.days_since_activity, 999) > 30 THEN 1 ELSE 0 END) AS engagement_gaps,
  SUM(CASE WHEN COALESCE(pa.has_payments, 0) = 0 OR COALESCE(pa.has_shop_pay, 0) = 0 THEN 1 ELSE 0 END) AS foundation_gaps
FROM target_accounts t
LEFT JOIN account_metrics am ON t.account_id = am.account_id
LEFT JOIN activity act ON t.account_id = act.account_id
LEFT JOIN product_adoption pa ON t.account_id = pa.account_id
GROUP BY t.csm_name, t.csm_email, t.segment, t.lead_name
```

**Query interpretation — what the results tell you about coaching needs:**

| Result | What It Means | Coaching Implication |
|--------|---------------|---------------------|
| `at_risk_count` = 0 | Clean book — no acute risk | Use session for development, not triage |
| `at_risk_count` = 1-3 (< 15%) | Normal risk load | Brief check: "How are you handling [accounts]?" |
| `at_risk_count` = 4-6 (15-25%) | Elevated risk | Discuss prioritization: "Which of these are you most worried about?" |
| `at_risk_count` > 6 (> 25%) | Portfolio under stress | Capacity conversation: "Do you need help? Should we escalate any?" |
| `engagement_gaps` > `at_risk_count` | Disengaged accounts exceed risk accounts | CSM may be avoiding difficult conversations — coach on this pattern |
| `engagement_gaps` = 0 | All accounts contacted within targets | Positive signal — acknowledge it |
| `foundation_gaps` > 3 | Multiple accounts missing Payments/Shop Pay | Product adoption playbook needed — is CSM comfortable with the pitch? |
| `avg_health_score` > 75 | Healthy portfolio | Growth-focused session |
| `avg_health_score` 55-75 | Mixed portfolio | Balance: protect at-risk + grow healthy |
| `avg_health_score` < 55 | Portfolio struggling | Support-focused session — what does the CSM need from you? |
| Returns 0 rows | CSM email doesn't match `sales_accounts` | Verify email. CSM may be new (< 2 weeks, accounts not yet assigned) or on leave. |

**From CS Compass Quick.db — Coaching History:**

Replace `@csm_email` with the CSM's actual email address (lowercase).

```
Collection: coaching_sessions
Filter: csm_email = @csm_email, status = 'completed'
Sort: session_date DESC, Limit: 3
```
*Interpretation: If returns 0 → no prior tracked sessions (normal for new relationships). If last session_date > 30 days ago → coaching cadence has lapsed. Check `session_type` distribution — all `protect` = reactive pattern. Fields to extract: `notes`, `commitments`, `wins`, `challenges`, `topics_discussed`, `weekly_triage.meetings_count`.*

```
Collection: coaching_goals
Filter: owner_email = @csm_email, status = 'active'
```
*Interpretation: If returns 0 → no active goals (gap — every CSM should have at least one). If goal has `progress = 0` and `target_date` within 30 days → stalled goal, surface in prep. Extract: `title`, `description`, `progress`, `target_date`, `category` (development/performance/account).*

```
Collection: coaching_actions
Filter: assignee_email = @csm_email, status IN ('pending', 'in_progress')
```
*Interpretation: Count items where `due_date < today` → overdue actions. 1-2 overdue = normal. 3+ = backlog, discuss capacity. If `created_by_email` ≠ `assignee_email` → action was assigned by lead, track accountability. Extract: `title`, `due_date`, `status`, `priority`.*

```
Collection: coaching_calls (or weekly partitions coaching_calls_YYYY_WNN)
Filter: csm_email = @csm_email, Sort: scored_at DESC, Limit: 10
```
*Interpretation: Average the `discovery`, `value`, `accountability` dimension scores (each 1-5). If < 3 scored calls in L30 → insufficient data for trends. If any dimension < 2.5 average → coaching opportunity. Look for trend: improving scores = acknowledge; declining = investigate. Extract: `discovery_score`, `value_score`, `accountability_score`, `overall_score`, `call_date`, `account_name`.*

### Step 2: Analyze Patterns — Decision Tree

Walk through these checks in order. Each YES adds a topic to the Must Discuss section (max 3).

**Check A: Portfolio Under Stress?**
- Is `at_risk_count` > 20% of their book? (e.g., >5 of 25 accounts)
  - **YES** → Is `engagement_gaps` also > 5?
    - **YES** → 🔴 Must Discuss: "Portfolio under stress AND engagement slipping. Is this capacity, avoidance, or prioritization? Ask: 'Which accounts are you choosing NOT to engage, and why?'"
    - **NO** → 🔴 Must Discuss: "High risk load but staying engaged. Validate their triage approach: 'Walk me through how you're prioritizing these.'"
  - **NO** → Continue to Check B.

**Check B: Call Quality Trending?**
- Do they have ≥ 3 scored calls in the last 30 days?
  - **YES** → Is any dimension averaging < 2.5/5?
    - **YES** → Which dimension?
      - Discovery < 2.5 → 🔴 Must Discuss: "Discovery gap — CSM may be jumping to solutions. Coaching: 'On your next call, try asking two more questions before proposing anything.'"
      - Value < 2.5 → 🟡 Check In: "Value articulation gap — CSM may not be connecting features to business outcomes. Suggest value narrative exercise."
      - Accountability < 2.5 → 🟡 Check In: "Accountability gap — calls may lack clear next steps. Review a recent call together: 'What commitments did you leave with?'"
    - **NO** → Note as positive: "Call quality solid across all dimensions."
  - **NO** → Note: "Insufficient call data — consider scoring a call together in this session."

**Check C: Action Item Health?**
- Are there overdue actions (status = 'pending' or 'in_progress' AND due_date < today)?
  - **YES** → How many overdue?
    - 1-2 overdue → 🟡 Check In: "Quick follow-up on [action titles]. Is anything blocking completion?"
    - 3+ overdue → 🔴 Must Discuss: "Action backlog — [N] overdue items. Frame as capacity, not accountability: 'Let's look at your action list together. Should we reprioritize or remove any of these?'"
  - **NO** → Note as positive: "All actions on track."

**Check D: Goal Progress?**
- Are there active goals with target_date within 30 days AND progress < 50%?
  - **YES** → 🟡 Check In: "Goal '[title]' is [N]% complete with [N] days to target. Ask: 'Is this still the right goal? Do you need the target adjusted?'"
  - **NO** → Skip — goals are on track or distant.

**Check E: Coaching Session Pattern?**
- Look at last 3 session types. Are they all `protect`?
  - **YES** → 🟡 Coaching Note: "Three consecutive protect-type sessions. CSM may be stuck in reactive mode. Consider shifting this session to `growth` or `development` focus."
  - **NO** → Skip.

**Check F: Value Engine Quadrant?**
- What is the CSM's current quadrant? (If value_engine_snapshots data available)
  - PASSENGER → 🔴 Must Discuss: "Low activity + poor outcomes. Needs direct conversation: 'What's getting in the way of engaging your accounts?'"
  - UNLUCKY → 🟡 Check In: "High effort, poor outcomes. CSM needs support, not pressure: 'You're doing the work — let's figure out why results aren't following.'"
  - LUCKY → 🟡 Coaching Note: "Good outcomes but low activity. May not sustain. Gently probe: 'Which accounts are driving your results? What happens if those change?'"
  - ENGINE → Note as positive: "Strong performance — use this session for development and career growth."

**Red flags (always surface if found):**
- Sentiment alerts on any account with GMV > $5M
- CSM mentioned in #help-salesforce or escalation channels in last 7 days
- Risk mitigation action in `pending_lead` status (Lead needs to act, not the CSM)

### Step 2b: Determine Session Type

Based on the checks above, classify this 1:1's recommended focus:

- **Any 🔴 Must Discuss items from Checks A or F (PASSENGER)?** → Session type: `protect`. Lead the agenda with risk and capacity. Reserve 5 min for development.
- **No 🔴 items, but `foundation_gaps` > 3?** → Session type: `foundations`. Focus on product adoption playbook, platform training, onboarding account support.
- **No 🔴 items, but 2+ 🟡 Check Ins?** → Session type: `weekly` or `general`. Balanced agenda: brief account check-ins + goal review + development.
- **No 🔴 items, 0-1 🟡 items, CSM quadrant = ENGINE?** → Session type: `development`. Flip the script — spend 15+ min on career growth, skill development, stretch opportunities. Accounts are handled.
- **No 🔴 items, CSM has expansion opportunities?** → Session type: `growth`. Focus on how to capture opportunity, not manage risk.
- **Lead specified a topic?** → Override above. Use the lead's topic as the anchor, fill remaining time based on the classification.

Surface the session type in the prep card header. This helps the lead set the right tone before the conversation starts.

### Step 2c: Build Commitment Carry-Forward

Extract commitments from the last 1-3 coaching sessions and classify:

For each prior session's `commitments` field:
- **CSM commitments** (things the CSM said they'd do): Check if there's a matching action item in `coaching_actions` with status `completed`. If no matching action or status still `pending` → carry forward as 🟡 "Check: Did [CSM] complete [commitment]?"
- **Lead commitments** (things the Lead said they'd do): Track these separately — the lead is accountable. If unresolved → flag: "You committed to [X] on [date]. Update?"
- **Joint commitments** (things both agreed to): Check if outcome is visible in the data (e.g., "schedule call with Account X" → check activity data for that account).

**Real examples from CS Compass data:**
- Session commitment: "Provide update on top risk accounts from High and Medium priority tiers" → Check: Has the CSM's engagement_gaps count decreased since that session?
- Session commitment: "Book 15 meetings this sprint" → Check: Does `weekly_triage.meetings_count` from the most recent session show progress toward 15?
- Session commitment: "Complete account transition sheet for leave coverage" → Check: Is there a completed action item matching this title?

If no commitments found in prior sessions, note: "No tracked commitments to follow up on. Consider asking: 'What did we agree on last time?'"

### Step 3: Generate Coaching Prep Card

---

## Output Template

```markdown
# Coaching Prep: [CSM Name]
**Date:** [1:1 date] | **Segment:** [segment] | **Book:** [N] accounts | **Lead:** [Lead Name]

## 📊 Performance Snapshot
| Metric | Value | Trend | Context |
|--------|-------|-------|---------|
| Avg Health Score | [N]/100 | [↑↓→] | [vs segment avg] |
| At-Risk Accounts | [N] of [total] | [↑↓→] | [vs last month] |
| Engagement Compliance | [N]% on track | [↑↓→] | [target: X%] |
| Foundation Gaps | [N] accounts | | [missing Payments/Shop Pay] |
| Call Quality (L30) | [N]/5 avg | [↑↓→] | Weakest: [dimension] |
| Open Actions | [N] ([M] overdue) | | |

## 🔴 Must Discuss (bring these up)
[Items that require the lead's attention or input — max 3]

1. **[Topic]**: [Why it matters + specific data point]
   - *Coaching angle:* [How to frame this constructively]

2. **[Topic]**: [Why it matters]
   - *Coaching angle:* [Framing]

## 🟡 Check In On (ask for update)
[Carry-forward from last session + active goals/actions]

- **Last 1:1 ([date]):** Topics: [list]. Commitments: [list with status]
- **Goal: [title]** — Progress: [N]% — Due: [date] — [on track / at risk / stalled]
- **Action: [title]** — Status: [pending/overdue] — Due: [date]

## 📞 Call Quality Deep-Dive
- **Avg score (L30):** [N]/5 across [N] scored calls
- **Strongest dimension:** [Discovery/Value/Accountability] — [what they do well]
- **Weakest dimension:** [Discovery/Value/Accountability] ([N]/5) — [specific pattern]
- **Coaching suggestion:** [Specific technique or focus for improvement]
- **Example call to reference:** [Call title, date, score — if available]

## 📋 Suggested Agenda (30 min)
1. **Wins & updates** (5 min) — Let CSM share first. Listen for energy level and confidence.
2. **[Must-discuss topic 1]** (10 min) — [Coaching approach: ask before telling]
3. **[Must-discuss topic 2]** (5 min) — [Quick check or decision needed]
4. **Goal/action review** (5 min) — [Specific items to check on]
5. **Development** (5 min) — [Prompt: "What skill are you working on? How can I help?"]

## 💡 Coaching Notes
- [Pattern observation]: "[CSM] has had [N] protect-type sessions in a row — may need to shift to growth/development focus."
- [Positive signal]: "[CSM]'s call accountability scores improved from [X] to [Y] — acknowledge this."
- [Watch item]: "[CSM] has [N] overdue actions — worth understanding if workload or prioritization issue."
```

**Conditional sections:**
- If **no prior coaching sessions found** → Replace "Check In On" with: "This appears to be the first tracked 1:1. Suggest starting with: What's working well? What's your biggest challenge right now? What do you need from me?"
- If **no call scores available** → Skip Call Quality Deep-Dive, note: "No scored calls in the last 30 days. Consider reviewing a recent call together in this session."
- If **CSM has 0 at-risk accounts and high engagement** → Shorten Must Discuss, expand Development section: "Portfolio is healthy — use this session for growth and skill development."
- If **lead specifies a topic** → Promote that topic to #1 in Must Discuss regardless of data.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| BQ unavailable | Use CS Compass coaching data only. Prep card focuses on coaching history, goals, and actions — skip portfolio metrics. Note: "Portfolio data unavailable — prep based on coaching history only." |
| CS Compass Quick.db unavailable | Use BQ portfolio data only. Prep card focuses on account health, engagement, and risk — skip coaching history. Note: "No prior session data — recommend starting with open discussion." |
| Both BQ and Quick.db unavailable | Fall back to framework-based prep. Ask lead: "What did you discuss last time? How are their accounts? Any concerns?" Build a structured agenda from their input using the 5-block format. |
| CSM email returns 0 accounts | CSM may be new, on leave, or email is wrong. Ask lead to verify. If CSM is genuinely new: "New CSM — suggest onboarding-focused 1:1: book tour, expectations, segment introduction." |
| No prior coaching sessions | Normal for new coaching relationships. Note this and suggest ice-breaker format. Do NOT treat as a gap. |
| All call scores are the same dimension weakness | Strong coaching signal — highlight: "Consistent [dimension] gap across [N] calls. Consider focused coaching exercise or call shadowing." |
| CSM has > 10 overdue actions | Workload issue, not laziness. Frame as: "Action backlog suggests capacity strain — discuss prioritization and whether some actions should be deprioritized or delegated." |
| Lead asks to prep for a CSM not on their team | Check if lead has admin/super_admin access. If yes, proceed. If no: "This CSM reports to [other lead]. You can still review their data, but coaching actions should go through their direct lead." |
| Lead asks for the CSM's prep (not the lead's prep) | Out of scope. Direct to: "This skill prepares YOUR coaching agenda. For the CSM's self-prep, they should use the manager-one-on-one-prep framework: What Changed → Accounts → Asks → Development." |
| Lead says "prep for my team" (ambiguous — all CSMs or one?) | Clarify: "Do you want (a) a quick summary across all your CSMs, or (b) a deep coaching prep for one specific CSM? For team overview, I'll produce a one-page summary. For a 1:1, I need the CSM's name." |
| CSM name is ambiguous (multiple matches) | If BQ returns multiple CSMs for a partial name match: "Found [N] CSMs matching '[name]': [list with emails and segments]. Which one?" Do NOT guess. |
| CSM has no accounts assigned yet (new hire) | Portfolio query returns 0 accounts but CSM exists in `sales_users`. Prep an onboarding-focused session: "CSM is active but has no accounts yet. Suggest onboarding 1:1: review segment expectations, introduce key tools (CS Compass, Salesforce), set first 30-day goals." |
| BQ returns portfolio data but Quick.db has no coaching history | Normal for new coaching relationships or leads who haven't used CS Compass's coaching module. Produce the prep card from portfolio data only. Under "Check In On" write: "No prior sessions tracked — this is a fresh start. Consider logging this session in CS Compass to build history." |
| Quick.db has coaching history but BQ is down | Produce a coaching-history-focused prep: prior commitments, goal progress, action items, call scores. Skip portfolio metrics. Note: "Portfolio data unavailable — focusing on coaching continuity." |
| Call scores show dramatic single-session drop (e.g., 4.5 → 1.5) | May be a data quality issue (wrong call scored, transcript error) rather than real performance drop. Flag: "⚠️ Unusual call score drop — verify before discussing. May be transcript/scoring error." |

---

## Anti-Patterns

- Do NOT turn the coaching prep into a performance review. The goal is **coaching** — helping the CSM improve — not evaluation. Frame everything as "how can I help" not "why didn't you."
- Do NOT surface raw call scores without coaching context. "Your Discovery score is 2.1" is a judgment. "Your Discovery scores suggest you're diving into solutions before fully understanding the customer's situation — let's work on asking one more 'why' question before proposing" is coaching.
- Do NOT recommend discussing more than 3 topics in Must Discuss. A 30-minute 1:1 cannot cover 5 urgent items. Prioritize ruthlessly — the rest goes in a follow-up or async message.
- Do NOT skip the Development block. If every 1:1 is account triage, the CSM gets operational support but no career growth. Leads who skip development lose their best people.
- Do NOT confuse **coverage assignment** with **compensation assignment**. The CSM's portfolio in `sales_accounts` may include coverage accounts (LOA coverage). Coach on what they're managing, but be aware that NRR attribution may differ.
- Do NOT present the prep card as a script. It's a **preparation tool** — the lead should adapt in real-time based on the conversation. The suggested agenda is a starting point, not a mandate.
- Do NOT recommend specific coaching techniques without data support. "You should coach them on accountability" requires evidence (call scores, missed actions). Generic coaching advice wastes the lead's prep time.

## Related Skills

| Need | Skill |
|------|-------|
| Triage a specific account the CSM raised | `csm-portfolio-triage` |
| Deep-dive on an at-risk account | `risk-mitigation-playbook` |
| Score a specific call together | `csm-call-scoring` |
| Review NRR pacing for the CSM | `nrr-pacing` |
| CSM's own 1:1 prep (their perspective) | `manager-one-on-one-prep` (Stephen Rogan) |
| Track action items from this session | `qbr-action-tracker` or CS Compass coaching module |
