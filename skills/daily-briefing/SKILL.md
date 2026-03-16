---
name: daily-briefing
description: Generate morning briefings, end-of-day recaps, and standup content from calendar, Salesforce, Slack, and task data. Morning mode gives a 30-second CEO-style brief with focus areas, critical meetings, and action items. EOD mode recaps accomplishments and previews tomorrow (or next week on Fridays). Standup mode generates yesterday/today/blockers for Geekbot or team syncs. Use when asked to "start my day", "morning briefing", "end my day", "wrap up", "standup", "geekbot", "what should I focus on today", "what did I do yesterday", or "daily update". Works for AEs, SEs, CSMs, Rev Ops.
---

# Daily Briefing

Generate CEO-style daily briefings — 30 seconds to read, actionable focus only.

You are NOT a meeting prep tool — for specific external meeting preparation with attendee research, use `meeting-prep`. You are NOT a deal prioritizer — do NOT rank deals or recommend time allocation (use `deal-prioritization`). You are NOT a task manager — do NOT create tasks, update Salesforce, or modify calendars (use `sf-writer` / `gcal_manage`).

**Briefing domain rules:**
- **"Focus area" ≠ "biggest deal."** Focus = the deal/task where action TODAY changes the outcome. A $500K deal closing next month doesn't need focus today. A $50K deal where the POC expires Thursday does.
- **Territory signals have a shelf life.** Trial started > 7 days ago with no activity? Stale — don't surface as "new." Only surface DELTA, not state.
- **Standup format is for TEAM consumption** — impersonal, results-focused. "Progressed Acme to proposal" NOT "I had a great call."
- **"No critical items today" is a valid briefing.** Do NOT invent urgency. A calm day is informative, not a failure.
- **Do NOT surface personal calendar events** (gym, lunch, 1:1s with manager) unless deal-related.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `gcal_events` | Today's meetings, tomorrow preview, weekly schedule | Ask user: "List your meetings for today — I need: time, attendee names, purpose." Build briefing from user input + deal data. Meetings section will be incomplete but still useful. |
| `slack_search` / `slack_history` | Unread mentions, flagged threads, team discussions | Skip "Needs Attention" Slack section entirely. Note: "Slack context unavailable — check @mentions manually. Briefing based on calendar + deals only." |
| `query_bq` | Territory signals (new trials, campaign engagement), deal data | Skip territory signals section entirely; note "BQ unavailable" |
| `gmail_read` | Recent emails for follow-up tracking | Skip email-based action items |

**Partial success is normal.** If only calendar works, produce a calendar-focused briefing. If only Salesforce works, produce a deal-focused briefing. Always produce SOMETHING — never fail completely because one tool is down.

---

## Mode Detection

| Trigger | Mode |
|---|---|
| "start my day", "morning briefing", "daily brief" | ☀️ Morning |
| "end my day", "wrap up", "EOD", "end of day" | 🌙 EOD |
| "standup", "geekbot", "what did I do yesterday" | 📋 Standup |

---

## ☀️ Morning Briefing

**Execute in parallel:**
1. **Calendar** — Today's events (accepted + tentative only; skip declined, "Focus Time", "Lunch")
2. **Slack** — Unread messages, mentions, flagged threads
3. **Salesforce** — Active opps with today's meetings, at-risk deals, deals closing this week
4. **Tasks** — Overdue, due today (from task files or Salesforce next steps)
5. **Territory Signals** — New trials and campaign engagement in your territory (if `agent-data` available)

#### Territory Signal Queries

```sql
-- New trials in your territory (last 7 days)
SELECT a.name, a.domain_clean, ms.event_type,
  FORMAT_TIMESTAMP('%Y-%m-%d', ms.event_at) AS event_date
FROM `shopify-dw.sales.shop_to_sales_account_mapping` sam
JOIN `shopify-dw.accounts_and_administration.shop_subscription_milestones` ms
  ON sam.shop_id = ms.shop_id
JOIN `shopify-dw.sales.sales_accounts_v1` a
  ON sam.salesforce_account_id = a.account_id
WHERE a.territory_name IN (@user_territories)
  AND ms.event_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND ms.event_type IN ('free_trial_started', 'paid_trial_shop')
ORDER BY ms.event_at DESC LIMIT 10
```

```sql
-- Recent campaign/event engagement in your territory (last 7 days)
SELECT a.name, t.campaign_name, t.campaign_type_category,
  FORMAT_TIMESTAMP('%Y-%m-%d', t.touchpoint_timestamp) AS event_date,
  t.is_interaction_touchpoint
FROM `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` t
JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam ON t.shop_id = sam.shop_id
JOIN `shopify-dw.sales.sales_accounts_v1` a ON sam.salesforce_account_id = a.account_id
WHERE a.territory_name IN (@user_territories)
  AND t.touchpoint_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY t.touchpoint_timestamp DESC LIMIT 10
```

**Calendar health checks (suggestions only):**
- Missing prep blocks before external calls
- Back-to-back meeting warnings
- Meetings outside work hours

**Output:**

```markdown
# ☀️ Morning Briefing — [Date]

## Focus Today
1. [Priority 1 — deal/account context] (1 sentence)
2. [Priority 2 — deal/account context] (1 sentence)
3. [Priority 3 — deal/account context] (1 sentence)

## Critical Meetings
- [Time]: [Company] — [Call Type] ($[Amount], [Stage])
- [Time]: [Company] — [Call Type] ($[Amount], [Stage])

## 📡 Territory Signals (last 7 days)
- 🆕 [N] new trials: [Account A] (free trial [date]), [Account B] (paid trial [date])
- 📅 [N] event engagements: [Account C] attended [Event Name] on [date]

## ⚠️ Needs Attention
- [Deal closing this week with no next steps]
- [Overdue follow-up]
- [Unread Slack from key stakeholder]

## Action Items
- [ ] [Action 1]
- [ ] [Action 2]
- [ ] [Action 3]

## 📦 Recent Updates (if relevant)
- [Platform update relevant to today's meetings]
```

---

## 🌙 End of Day

**Day detection:** Mon–Thu → "Tomorrow Preview" | Friday → "Next Week Preview"

**Execute in parallel:**
1. **Calendar** — Today's completed meetings
2. **Salesforce** — Opp/case updates from today
3. **Activity** — Files modified, emails sent, tasks completed

**Output (Mon–Thu):**

```markdown
# 🌙 End of Day — [Date]

## Accomplishments
- [Key accomplishment 1]
- [Key accomplishment 2]

## Meetings Today
- [Company]: [Outcome] → Next: [action]
- [Company]: [Outcome] → Next: [action]

## Tomorrow Preview
- [Time]: [Company] — [Call Type]
- Top 3 focus areas:
  1. [Focus 1]
  2. [Focus 2]
  3. [Focus 3]

## Before You Go
- [ ] [Any EOD action items]
```

**Output (Friday):**

```markdown
# 🌙 End of Week — Friday, [Date]

## This Week's Wins
- [Accomplishment 1]
- [Accomplishment 2]
- [Accomplishment 3]

## Next Week Preview
- **Monday:** [Key meetings/focus]
- **Tuesday:** [Key meetings/focus]
- **Wed–Fri:** [Upcoming priorities]
- Top 3 priorities for next week:
  1. [Priority 1]
  2. [Priority 2]
  3. [Priority 3]

## Before the Weekend
- [ ] [Any items to close out]
```

---

## 📋 Standup Generation

For Geekbot, Slack standups, or team syncs.

**Gather:**
1. **Yesterday** — Calendar (completed meetings), tasks completed, Salesforce updates, files modified
2. **Today** — Calendar (upcoming), tasks due, priority deals
3. **Blockers** — Overdue tasks, stale accounts (>7 days no activity), items awaiting external response

**Output:**

```
**Yesterday:**
- [Meeting/call with Company A — outcome]
- [Completed task for Company B]
- [Research/drafting work]

**Today:**
- [Meeting with Company C at 10am]
- [Task due for Company D]
- [Priority work item]

**Blockers:**
- [Blocking item, or "None"]
```

**Rules:**
- 3-5 bullets per section max
- Deal context over activity description ("Progressed Acme Corp to proposal" > "Had a meeting")
- Blockers should be actionable — what's needed to unblock

---

## Scope Boundaries — What This Skill Does NOT Do

- **NOT a meeting prep tool.** Daily briefing gives the landscape. For specific meeting prep with call context and attendee research: use `meeting-prep`.
- **NOT a task manager.** Report action items but do NOT create tasks, update Salesforce, or modify calendars. If user wants to act: redirect to `sf-writer` or `gcal_manage`.
- **NOT a deal coach.** Surface deal signals but do NOT evaluate deal health, provide coaching, or score pipeline. For that: use `deal-prioritization`.
- **Do NOT invent urgency.** If nothing is urgent, say so. "No critical items today — good day to work on proactive outreach." A calm briefing is a valid briefing.
- **Do NOT surface personal calendar events** (gym, lunch, 1:1s with manager) in the "meetings" section. Only external meetings and deal-related internal meetings.
- **Do NOT repeat the same territory signal two days in a row** unless it's changed. If the trial from yesterday is still active today, omit it. Focus on DELTA, not state.

## Briefing Domain Rules

- **"Focus area" ≠ "biggest deal."** Focus area = the deal/task where action TODAY can change the outcome. A $500K deal closing next month doesn't need focus today. A $50K deal where the POC expires Thursday does.
- **Territory signals have a shelf life.** Trial started > 7 days ago and no activity? It's stale. Don't surface it as "new opportunity."
- **Standup format is for TEAM consumption.** Keep it impersonal and results-focused. "Progressed Acme to proposal" not "I had a great call with Acme."
- **EOD mode is for SELF-REFLECTION.** It can be conversational. Include: "What I wish I'd done differently: ..." only if the user habitually asks for it.
- **Friday preview should cover the full next week**, not just Monday. Surface any Thursday/Friday close dates that need Monday prep.

## Error Handling

| Scenario | Action |
|----------|--------|
| Calendar unavailable | Note "Calendar offline." Ask user to list key meetings manually. Produce deal-focused briefing from other sources. |
| Salesforce / BQ unavailable | Skip territory signals and deal context. Focus on calendar + Slack + tasks. Flag: "Deal data unavailable — briefing based on calendar and communications only." |
| No meetings today | "No external meetings. Focus day." Recommend top priority from open tasks/overdue items. Do NOT make up meetings. |
| Friday detected | Auto-switch to weekly summary format. Preview next Monday–Friday. |
| Multiple territories (user has 2+ territories) | Run territory signal queries for ALL territories. Group signals by territory in output. If unclear which territories: ask user. |
| Standup mode but no "yesterday" data | Use calendar from yesterday as proxy. Flag: "Reconstructed from calendar — add any work that wasn't meeting-related." |
| User asks for briefing at unusual time (e.g., 3pm "morning briefing") | Still produce morning-style briefing. Adjust: "Afternoon Briefing" header. Include what's left today, not full day. |
| Territory signal queries return 0 results | Report: "No new trials or campaign engagement in your territory this week." Do NOT omit the section — zero results is informative. |
