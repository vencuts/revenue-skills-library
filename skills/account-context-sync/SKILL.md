---
name: account-context-sync
description: Synchronize account/deal context from Gmail, Slack, Google Drive, Salesforce, Salesloft, and Fellow into a unified local folder. Pulls all relevant communications, meeting notes, call transcripts, and deal data for a specific account or opportunity. Use when asked to "sync context for [account]", "pull everything on [deal]", "gather context", "build deal folder", "what do we know about [merchant]", "run the sync", or when preparing for deal reviews, loss analysis, or account planning. Works for AEs, SEs, CSMs, Rev Ops.
---

# Account Context Sync

Pull all available context for an account or opportunity into a structured local folder. **Execute immediately on trigger — no clarification questions.**

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `gmail_read` | Email threads with merchant/account contacts | Skip email folder. Note: "No email context — {source} unavailable." |
| `slack_search` | Account mentions in deal channels, internal discussions | Skip Slack folder. Note in briefing: "No Slack history checked." |
| `gdrive_search` | Prior proposals, decks, SOWs, meeting recordings for this account | Skip Drive folder. Note: "No Drive files synced." |
| `query_bq` | Salesloft call transcripts, SF activity signals, opp details, UAL lookup | Skip BQ-derived content. Briefing will lack call data and activity context. |
| `gcal_events` | Meeting history with this account (past + upcoming) | Skip meetings folder. Note: "No calendar data available." |
| `vault_search` | People lookup, team context, internal playbooks | Skip Vault section. Minor impact. |

**Graceful degradation**: Run whatever tools are available. Even a single-source sync (e.g., email only) is valuable — it centralizes context that was scattered. Never fail because one tool is down.

---

## Workflow

### Step 0: Data Integrity Pre-Flight

Before syncing, run `data-integrity-check` on the account. If duplicate SF accounts exist, you'll pull context from the WRONG account. If territory owner is inactive, the synced folder may be routed to a dead owner. Flag these in the sync summary so the user knows the data foundation is shaky.

### Step 1: Identify Target

Determine what to sync:
- **Account name** → search across all sources
- **Opportunity ID** → pull Salesforce opp + related account
- **Domain** → resolve to account via Salesforce or BigQuery
- **Email address** → identify account from email domain

### Step 2: Create Folder Structure

```
context/[account-slug]/
├── config.md              # Sync metadata + account summary
├── salesforce/
│   ├── opportunity.md     # Opp details, stage, amount, team
│   └── activity.md        # SF activity log
├── emails/
│   └── YYYY-MM-DD-subject.md
├── meeting-notes/
│   └── YYYY-MM-DD-type.md
├── transcripts/
│   └── YYYY-MM-DD-title.md
├── slack/
│   └── threads.md
├── drive-docs/
│   └── [doc-title].md
└── briefing.md            # Synthesized executive briefing
```

### Step 3: Gather Sources (Parallel)

Run all available sources simultaneously:

#### Salesforce (via `revenue-mcp` or `agent-data`)
- Opportunity: stage, amount, close date, owner, primary product, competitor, loss reason
- Account: name, industry, domain, annual revenue
- Activity: logged calls, emails, tasks from `salesforce_activity`
- Team: AE, SE, CSM assignments

#### Gmail (via `gworkspace`)
- Search by: attendee emails (excluding @shopify.com, @google.com, @salesloft.com)
- Lookback: 90 days (NEW sync) or since last sync (INCREMENTAL)
- Classify: meeting notes vs email threads (see Content Classification below)

#### Slack (via `agent-slack`)
- Search by: account name, domain, key contact names
- Lookback: 90 days or since last sync
- Capture: channel name, thread summary, participants

#### Google Drive (via `gworkspace`)
- Search by: account name, domain
- Filter: modified in last 90 days, exclude images
- Read: full content of top 5 most recent docs

#### Salesloft Transcripts (via `agent-data`)
```sql
-- Find all transcripts for this account
WITH account_people AS (
  SELECT p.email_address
  FROM `shopify-dw.base.base__salesloft_people` p
  JOIN `shopify-dw.base.base__salesloft_accounts` sa ON p.account.id = sa.salesloft_account_id
  WHERE sa.crm_id = '[SF_ACCOUNT_ID]'
)
SELECT c.conversation_id, c.title, c.duration, c.event_start_date,
       c.summary.text as summary
FROM `shopify-dw.base.base__salesloft_conversations_extensive` c,
     UNNEST(c.attendees) a
JOIN account_people ap ON LOWER(a.email) = LOWER(ap.email_address)
WHERE c.event_start_date >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
GROUP BY 1,2,3,4,5
ORDER BY c.event_start_date DESC
```

#### Fellow (via `fellow-mcp`)
- Match meeting IDs from calendar events
- Merge with Gemini transcripts: Fellow content tagged `*(Fellow)*`
- Extract action items with owners and due dates

### Step 4: Content Classification

Route by content type, not source:

| Pattern | Classification | Destination |
|---|---|---|
| "Meeting Notes", "Transcript", "Call Summary", "Discovery Call", "Demo" | Meeting note | `meeting-notes/` |
| "Re:", "Fwd:", email threads | Email | `emails/` |
| Salesloft recording with summary | Transcript | `transcripts/` |
| Google Doc (TA, briefing, SOW) | Drive doc | `drive-docs/` |
| Slack thread | Slack | `slack/threads.md` |

### Step 5: Synthesize Briefing

After all sources gathered, create `briefing.md`:

```markdown
# Account Briefing: [Account Name]

**Last Synced:** [Timestamp]
**Sources:** [List of MCPs used]

## Executive Summary
[2-3 paragraphs synthesizing the full picture]

## Deal Status
- **Opp:** [Name] | **Stage:** [Stage] | **Amount:** $[X]
- **Close Date:** [Date] | **Days in Stage:** [N]
- **Team:** AE: [Name], SE: [Name], CSM: [Name]
- **Competitor:** [If known]

## Key People
| Name | Role | Company | Last Contact | Notes |
|---|---|---|---|---|
| [Name] | [Title] | [Company] | [Date] | [Champion/Blocker/Decision-maker] |

## Timeline
- [Date]: [Event — email, call, meeting, stage change]
- [Date]: [Event]

## Open Items
- [ ] [Action item with owner]
- [ ] [Action item]

## Risk Signals
- [Identified risks from the data]

## Content Index
- [N] emails | [N] meeting notes | [N] transcripts | [N] Slack threads | [N] Drive docs
```

### Step 6: Update Sync Metadata

Write `config.md`:

```markdown
# Sync Config: [Account Name]

**Account ID:** [SF Account ID]
**Opportunity ID:** [SF Opp ID]
**Domain:** [domain.com]
**Last Synced:** [ISO timestamp]
**Sync Type:** [NEW / INCREMENTAL]

## Source Results
| Source | Items Found | New Since Last |
|---|---|---|
| Gmail | [N] | [N] |
| Slack | [N] | [N] |
| Drive | [N] | [N] |
| Salesloft | [N] | [N] |
| Fellow | [N] | [N] |
| Salesforce | [N activities] | — |
```

---

## Sync Types

| Type | Condition | Lookback |
|---|---|---|
| **NEW** | No prior sync or >12 months ago | 12 months (all sources) |
| **INCREMENTAL** | Last sync within 12 months | Since last sync timestamp |
| **STALE** | Last sync 12-24 months ago | Ask user: full resync or skip? |

---

## Content Write Guardrail

**MANDATORY:** Never update config.md without first writing raw content to proper file locations.

- Emails with substance → save to `emails/YYYY-MM-DD-subject-slug.md`
- Meeting notes/transcripts → save to `meeting-notes/` or `transcripts/`
- Slack context → append to `slack/threads.md`
- **Then** update config.md with sync summary
- Summaries reference files — they are NOT a substitute for raw content

---

## Output

```
📁 Context Sync Complete — [Account Name]
Type: [NEW|INCREMENTAL] | Lookback: [X] days

Results: Gmail [N] | Slack [N] | Drive [N] | Salesloft [N] | Fellow [N] | SF [N activities]
Files Written: [N] emails, [N] meeting notes, [N] transcripts
Briefing: Updated ✅
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| One or more tools unavailable | Continue with remaining tools. Never fail completely. Note gaps in sync summary: "Sources synced: Gmail ✅, Slack ✅, BQ ❌ (access denied)" |
| No Salesforce opp found | Create folder with account name only. Note: "No active Salesforce opportunity — folder created from account name. If this is a net-new prospect, data will be sparse." |
| Account name matches multiple Salesforce accounts | List all matches with domains and opp counts. Ask: "Which account? I found {N} matches." Or: use domain to disambiguate. |
| Zero results from ALL sources | Check: (1) spelling/domain correct? (2) account may be under a parent company name (3) try alternate names. If still nothing: "No data found for '{name}'. This may be a net-new account with no prior Shopify interaction." |
| Email search returns hundreds of results | Filter to last 90 days. If still > 50 threads: focus on threads with 3+ replies (high-signal), skip single-message notifications. Note: "Filtered to high-engagement threads." |
| Conflicting data across sources (e.g., different close dates in SF vs email) | Report BOTH values. "Salesforce shows close date {X}, but email thread from {date} mentions {Y}. Verify which is current." |
| Incremental sync finds no new content since last sync | Report: "No new content since last sync on {date}. Account context is current." Don't regenerate the briefing — it wastes time. |
| Salesloft transcripts are very long (> 10K words) | Save full transcript but excerpt key moments (first 500 words + AI summary) in the briefing. Note: "Full transcript in {file} — briefing shows summary." |
