---
name: meeting-prep
description: Generate call preparation briefings for upcoming external meetings. Scans calendar (next 48h), gathers context from Salesforce, Gmail, Slack, Google Drive, Vault, and Salesloft call transcripts — then synthesizes a prioritized prep card per meeting. Use when asked to "prep for calls", "get me ready for tomorrow", "call prep", "meeting prep", "what meetings do I have", or "generate digest". Works for AEs, SEs, CSMs, Rev Ops — any revenue role with external meetings.
---

# Meeting Prep

Generate prioritized call preparation briefings by gathering context from every available source. **Execute immediately on trigger — no clarification questions.**

**[INTERNAL-ONLY]** — preparation materials, do not share externally.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `gcal_events` | Today's/tomorrow's meetings with attendees | Ask user to list meetings manually. Cannot auto-discover external meetings. |
| `query_bq` | Salesforce opp details, Salesloft call transcripts, UAL account lookup, activity signals | Skip deal-specific context. Note: "No Salesforce data — prep card based on calendar + email only." |
| `gmail_read` | Recent email threads with attendees for context and open questions | Skip email thread section. Note: "No email context available." |
| `gdrive_search` | Find prior proposals, decks, meeting notes for this account | Skip "prior materials" section. |
| `slack_search` | Recent Slack mentions of this account or attendee | Skip "internal discussions" section. |
| `vault_search` | Product updates, internal docs relevant to meeting topics | Skip "Shopify updates to share" section. |

**Graceful degradation**: Produce the best prep card possible with whatever tools work. A calendar-only prep card (meeting time + attendees + agenda) is still useful. Never fail completely because one tool is down.

---

## Workflow

### Step 0: Data Integrity Pre-Flight (runs per-account during prep)

As you prep each meeting, run `data-integrity-check` on the associated account. If UAL data is incomplete (null revenue, null fit scores), your prep card should note: "⚠️ Limited data — UAL record incomplete for [account]. Recommend confirming [field] during discovery." This turns a data gap into a discovery question.

### Step 1: Get Upcoming Meetings (next 48h)

Query calendar for events where user is accepted/tentative/organizer in the next 48 hours.

### Step 2: Classify Meetings

- **External** = any attendee NOT `@shopify.com` → full prep card
- **Internal** = all Shopify attendees → brief one-line summary only
- Skip: declined, all-day events, "Focus Time", "Lunch"

### Step 3: Gather Context (parallel per external meeting)

Run all available sources simultaneously:

| Source | What to Gather | Tool |
|---|---|---|
| **Enriched Account** | Industry, revenue, platform, grade, priority, CSM, territory, primary_shop_id (from `sales_accounts_v1`) | `agent-data` |
| **Engagement Signals** | Trial status (`shop_subscription_milestones`), recent events/webinars (`shop_linked_salesforce_campaign_touchpoints`) | `agent-data` |
| **Salesforce** | Opp stage, amount, close date, next steps, loss reason (if CL), owner, primary product | `revenue-mcp` or `agent-data` |
| **Gmail** | Last 30 days of threads with attendee emails (exclude @shopify.com, @google.com, @salesloft.com) | `gworkspace` |
| **Google Drive** | Most recent docs matching company/org name (last 90 days) | `gworkspace` |
| **Slack** | Recent messages mentioning company name or attendee name | `agent-slack` or `slack-mcp` |
| **Vault** | Relevant product updates, team context for Shopify attendees | `agent-vault` or `vault-mcp` |
| **Salesloft Transcripts** | Recent call recordings with this merchant (via BQ `base__salesloft_conversations_extensive`) | `agent-data` |
| **Fellow** | Meeting notes from prior meetings with same attendees | `fellow-mcp` |

#### Enriched Account + Engagement Signals Query

```sql
-- Enriched account context (run with UAL account lookup)
SELECT a.industry, a.annual_total_revenue_usd AS revenue, a.ecomm_platform,
  a.account_grade, a.account_priority_d2c AS priority, a.sales_lifecycle_stage,
  a.plus_status, a.primary_shop_id, a.merchant_success_manager,
  a.territory_segment, a.domain_clean
FROM `shopify-dw.sales.sales_accounts_v1` a
WHERE a.account_id = @sf_account_id
LIMIT 1
```

```sql
-- Trial status (is the account actively evaluating?)
SELECT ms.event_type, FORMAT_TIMESTAMP('%Y-%m-%d', ms.event_at) AS event_date
FROM `shopify-dw.sales.shop_to_sales_account_mapping` sam
JOIN `shopify-dw.accounts_and_administration.shop_subscription_milestones` ms
  ON sam.shop_id = ms.shop_id
WHERE sam.salesforce_account_id = @sf_account_id
  AND ms.event_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
ORDER BY ms.event_at DESC LIMIT 5
```

```sql
-- Recent campaign/event engagement
SELECT t.campaign_name, t.campaign_type_category, t.campaign_member_status,
  FORMAT_TIMESTAMP('%Y-%m-%d', t.touchpoint_timestamp) AS event_date,
  t.is_interaction_touchpoint
FROM `shopify-dw.marketing.shop_linked_salesforce_campaign_touchpoints` t
JOIN `shopify-dw.sales.shop_to_sales_account_mapping` sam ON t.shop_id = sam.shop_id
WHERE sam.salesforce_account_id = @sf_account_id
  AND t.touchpoint_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
ORDER BY t.touchpoint_timestamp DESC LIMIT 10
```

### Step 4: Synthesize Prep Cards

Generate one card per external meeting, ordered by urgency:

```
## [🔴/🟡/🟢] [Meeting Title]
**Time:** [Day, Date] at [Time] [Timezone]
**With:** [External Attendee Name] ([Role/Title]) @ [Company]
**Shopify:** [Internal attendees and their roles]

### Account Context
- **Grade:** [A/B/C/D] | **Priority:** [High/Med/Low] | **Segment:** [territory_segment]
- **Platform:** [ecomm_platform] | **Plus:** [status] | **CSM:** [name or N/A]
- **Engagement:** [Trial started [date] / Attended [event] on [date] / No recent signals]

### Deal Context
- **Opp:** [Name] | **Stage:** [Stage] | **Amount:** $[X] | **Close:** [Date]
- **Product:** [Primary product interest]
- **Last Activity:** [Date — what happened]

### Recent Threads
- [Date]: [Summary of email/Slack thread — key points, action items]
- [Date]: [Another thread]

### Prior Call Insights
[From Salesloft transcripts or Fellow notes — what was discussed, what was promised, what objections came up]

### Open Questions
[Unanswered items from prior threads or calls]

### Suggested Prep
**Topics to Cover:**
- [Topic] — [Why it matters for this deal]

**Questions to Ask:**
- [Question based on deal context]

### Gaps
- [Missing info to research before the call]
```

**Priority legend:** 🔴 Today, 🟡 Tomorrow, 🟢 Later this week

---

## Prep Depth by Urgency

| Urgency | Depth | Time Estimate |
|---|---|---|
| 🔴 Today | Full: all sources, transcripts, Drive docs, open questions | ~5 min/meeting |
| 🟡 Tomorrow | Standard: SF + email + Slack + transcripts | ~3 min/meeting |
| 🟢 Later | Quick: SF context + last email thread | ~1 min/meeting |

---

## Salesloft Transcript Lookup

When `agent-data` is available, query for recent call transcripts:

```sql
SELECT c.title, c.duration, c.event_start_date, c.summary.text,
       ARRAY_AGG(STRUCT(a.full_name, a.email, a.is_internal)) as attendees
FROM `shopify-dw.base.base__salesloft_conversations_extensive` c,
     UNNEST(c.attendees) a
WHERE EXISTS (
  SELECT 1 FROM UNNEST(c.attendees) att
  WHERE att.email IN ([attendee_emails])
    AND att.is_internal = FALSE
)
AND c.event_start_date >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
GROUP BY 1,2,3,4
ORDER BY c.event_start_date DESC
LIMIT 5
```

Replace `[attendee_emails]` with quoted external attendee email addresses.

### UAL Account Lookup

Before Salesforce queries, resolve the account via UAL to get ownership and territory context:

```sql
SELECT
  COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
  COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
  territory_name,
  COALESCE(domain, domain_sf, domain_3p, domain_1p) AS best_domain,
  account_id AS sf_account_id
FROM `sdp-prd-commercial.mart.unified_account_list`
WHERE LOWER(COALESCE(domain, domain_sf, domain_3p, domain_1p))
      LIKE CONCAT('%', LOWER(@attendee_domain), '%')
   OR LOWER(COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p))
      LIKE CONCAT('%', LOWER(@company_name), '%')
LIMIT 5
```

Extract `@attendee_domain` from external attendee email (strip everything before `@`). This tells you who owns the account before you even look at Salesforce opps.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Calendar unavailable | Ask: "What meetings do you have today/tomorrow? List time, company, and attendees." Cannot auto-discover without calendar. |
| Attendee domain doesn't match any Salesforce account | Try UAL with domain, then by company name. If still no match: "New prospect — no Salesforce history. Use `prospect-researcher` for intel, or this is a net-new meeting." |
| Multiple Salesforce opps found for same account | List all with stages and amounts. Ask: "Which opp is this meeting about?" or present the most recent active one with a note. |
| No prior call transcripts found | Skip transcript section SILENTLY — don't highlight the absence (it's noise). Focus prep card on deal data and email context instead. |
| Meeting has no external attendees (all @shopify.com) | Flag: "This is an internal meeting. Meeting prep is designed for external calls. Want me to prep anyway, or switch to `daily-briefing` for internal context?" |
| Calendar event has no attendees listed | Check email thread for meeting invite context. If still unknown: "No attendees found — who are you meeting with? I need at least the company name." |
| Attendee works at a Shopify partner/agency (not a merchant) | Flag: "This attendee appears to be at a Shopify partner ({company}). Partner meetings have different dynamics — focus on mutual deal pipeline, not selling Shopify." |
| User asks to prep for meetings > 48 hours out | Warn: "Prepping more than 48h out — deal context may change. Recommend re-running prep the morning of the meeting." |
| Same company has a recent closed-lost opp | Flag prominently: "⚠️ Recent closed-lost opp ({date}, ${amount}, reason: {reason}). Be aware of prior history — this meeting may be a re-engagement. Do NOT open with the same pitch." |

---

## Output Summary

After all cards, append:

```
---
**📋 Prep Summary:** [N] external meetings prepped | Sources: [list of MCPs used]
**⚠️ Gaps:** [Any sources that were unavailable]
**Next:** [Suggest "Run the sync" if merchant context is stale]
```

---

## Detailed Format Reference

See `references/prep-card-format.md` for full template with all optional sections.

---


## Platform Reference Data
Load these files for current Shopify platform data before responding:
- `references/se-methodology.md` — SE methodology, discovery playbook, solutioning scenarios for pre-meeting context

## Knowledge Enrichment Directive

When conversation involves specific products or verticals, reference the appropriate domain advisor skill from `~/.claude/skills/product-*` or `~/.claude/skills/vertical-*`. Use `~/.claude/skills/skill-routing-index.json` to identify which domain applies based on the merchant's product interest or industry.

**Role adaptation:** See `~/.claude/skills/role-context.md` — frame prep cards for the user's role (AE: deal velocity focus; SE: technical architecture focus; CSM: adoption and health focus).
