---
name: sf-writer
description: Write to Salesforce fields — opportunity next steps, case notes, activity logs, and stage updates. Reads current values first, shows diff for confirmation, writes via Gumloop webhooks or revenue-mcp, then validates. Also handles new account folder creation and deal archival. Use when asked to "update Salesforce", "log next steps", "update the opp", "add case notes", "write to SF", "create merchant folder", "archive this deal", "update next steps for [account]", or "sync to Salesforce". Works for AEs, SEs, CSMs managing Salesforce records.
---

# Salesforce Writer

Write to Salesforce fields with a read → diff → confirm → write → validate flow. Never writes without reading first.

You are NOT a Salesforce admin — do NOT create custom fields, modify picklist values, or change page layouts. You WRITE to existing fields only. You are NOT a reporting tool — do NOT run aggregate queries or build dashboards (use `sales-manager-dashboard`). You NEVER write without user confirmation — the diff step is mandatory.

**Field constraints (enforced, not suggested):**
- `NextStep` — plain text, max 32,000 chars. Replace entirely on each update (it's a living field, not a log).
- `SE_Next_Steps__c` — SE-owned. AE should NOT overwrite unless SE is unavailable and deal is time-critical.
- `StageName` — picklist. Only valid progressions accepted (see Common Operations). Regression (e.g., Solution → Envision) requires manager override reason.
- `Description` on Cases — append with timestamp, never replace. History is sacrosanct.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `revenue-mcp` | SOQL queries + direct SF API writes (preferred write path) | Fall back to Gumloop webhooks. If webhooks also fail → generate copy-paste format (see below). |
| `query_bq` | Read-only SF data from `base__salesforce_banff_*` tables for verification | Use revenue-mcp SOQL instead. BQ data may be 24h stale — note if freshness matters. |
| `slack_search` | Check if someone already posted about this update in team channel | Skip. Not critical for writes. |

**Manual paste fallback (when ALL write tools fail):**
```
⚠️ Could not write to Salesforce automatically. Copy this into the field manually:

Record: [Opp/Case Name] ([ID])
Field: [Field Name]
Value to paste:
---
[exact content to paste]
---
Steps: Open SF → navigate to record → click Edit → paste into [field] → Save
```

**Write path priority:** revenue-mcp (direct API) → Gumloop webhook → manual paste format.
**Read path priority:** revenue-mcp SOQL (real-time) → BigQuery banff tables (24h delay).

---

## Core Principle

**Salesforce is the source of truth.** Always READ before WRITE. Never overwrite — merge.

---

## Write Flow

### Step 0: Determine What to Write

```
User says "update Salesforce" / "log next steps" / "write to SF"
│
├── Has opp ID or case ID? → Run data-integrity-check first (we're WRITING to SF — dirty data is worse here)
│   └── If duplicate accounts found → STOP. "⚠️ This account has duplicates in SF. Writing to the wrong record will make the problem worse. Confirm which account_id is correct before proceeding."
│   └── If integrity HIGH → Step 1 (read current)
│   └── If ID is invalid or record not found → "Record not found. Check the ID."
│
├── Has merchant name but no ID? → Search SF:
│   ├── 0 matches → "No matching records. Check spelling or provide ID directly."
│   ├── 1 match → Confirm → Step 1
│   └── Multiple → List all with stage + amount. "Which record?"
│
├── Has field name? → Map to operation (see Common Operations below)
│   ├── "next steps" → Next Steps field (replace entire content)
│   ├── "stage" → Stage update (validate progression — see Step 2 rules)
│   ├── "notes" / "activity" → Append (never overwrite history)
│   └── Unknown field → "Which Salesforce field? I support: Next Steps, Stage, Case Notes, Activity."
│
└── Vague request ("update the opp") → Ask: "What field and what value? E.g., 'update next steps to: Schedule demo for Thursday'"
```

### Step 1: Read Current Value

Query Salesforce for current field value:

```sql
SELECT Id, Name, StageName, Amount, CloseDate, NextStep,
       SE_Next_Steps__c, Primary_Product_Interest__c
FROM Opportunity
WHERE Id = '[OPP_ID]'
```

Or for Cases:
```sql
SELECT Id, CaseNumber, Subject, Status, Description
FROM Case
WHERE Id = '[CASE_ID]'
```

### Step 2: Merge Content

- **Next Steps field:** Replace entire content (it's a living field, not a log)
- **Case Notes:** Append new note with timestamp, preserve history
- **Activity log entries:** Always append, never modify existing

**Format for Next Steps:**
```
Next Steps: [Current actionable items — living line, replace when actions change]

[MMM D, YYYY]: [Most recent interaction — what happened]
[MMM D, YYYY]: [Previous interaction]
[MMM D, YYYY]: [Earlier interaction]
```

### Step 3: Show Diff

Display before/after for user confirmation:

```
📝 Salesforce Update Preview

**Record:** [Opp/Case Name] ([ID])
**Field:** [Field Name]

**BEFORE:**
[Current value]

**AFTER:**
[Proposed new value]

**Changes:**
- [What's being added/changed]

Confirm? [Yes / Edit / Cancel]
```

### Step 4: Execute Write

**Via revenue-mcp:** Direct Salesforce API write
**Via Gumloop:** Trigger webhook flow with record_id + field content + object_type

If using Gumloop, route to correct flow:
| Record Type | Action |
|---|---|
| Opportunity | Use Opportunity flow |
| Case | Use Case flow |

**Never guess Salesforce field API names.** Cases and Opportunities have different schemas. Let the write tool handle field mapping.

### Step 5: Validate

Wait 10 seconds, then re-query Salesforce to confirm the write succeeded:

```
✅ Salesforce Updated

**Record:** [Name]
**Field:** [Field]
**Verified:** [Timestamp] — value matches expected
```

If validation fails:
```
❌ Write Verification Failed

**Expected:** [What we wrote]
**Actual:** [What Salesforce shows]

Possible causes: workflow rule override, validation rule, permission issue
Retry? [Yes / No]
```

---

## Common Operations

### Update Opportunity Next Steps

1. Read current next steps from opp
2. User provides new action items
3. Format: living "Next Steps:" line + dated entry for today
4. Diff → Confirm → Write → Validate

### Log Activity / Call Notes

1. Read current activity on the opp
2. User provides call summary
3. Format as dated entry with key points and next steps
4. Diff → Confirm → Write → Validate

### Update Stage

1. Read current stage
2. User requests new stage
3. Check: is this a valid stage progression? (Don't skip stages without confirming)
4. Diff → Confirm → Write → Validate

### Case Notes (Launch/Post-Sales)

1. Read current case notes
2. User provides update
3. Append with timestamp, preserve history
4. Route to Case flow (different from Opportunity flow)
5. Diff → Confirm → Write → Validate

---

## Account Folder Management

### New Account / Opportunity

When a new deal or account needs to be set up:

1. **Create folder structure** (if using local merchant folders):
   ```
   context/[account-slug]/
   ├── config.md          # Account metadata, shop ID, sync timestamps
   ├── briefing.md        # Executive summary
   ├── salesforce/         # SF data snapshots
   ├── emails/             # Email threads
   ├── meeting-notes/      # Call notes, transcripts
   └── transcripts/        # Salesloft recordings
   ```

2. **Resolve Shop ID** — Use `shop-identification-by-domain` query if domain is known
3. **Initial sync** — Trigger `account-context-sync` skill for full context pull
4. **Store metadata** in config.md

### Archive Account

When deal is closed (won or lost):

1. **Verify in Salesforce** — Confirm closed status
2. **Per-account confirmation** — NEVER batch archive. Always confirm each one.
3. **Move to archive/** — Preserve for reference
4. **Note:** You may only see your own opps/cases — warn about visibility limits

---

## Auto-Detection

Determine record type from context:
- User mentions "opp", "opportunity", "deal", "close date" → Opportunity
- User mentions "case", "launch", "implementation", "ticket" → Case
- Ambiguous → Ask: "Is this an Opportunity or a Case?"

---

## Salesforce Domain Rules

- **`Next_Step` field is plain text, max 255 chars.** Truncate gracefully if content exceeds. Never write multi-paragraph narratives — use bullet points.
- **`Close_Date` is a DATE, not DATETIME.** Format as YYYY-MM-DD. Never include time component.
- **`Stage_Name` has a picklist of valid values.** Do NOT write free-text stage names. Valid stages: Envision, Demonstrate, Solution, Deal Craft, Closed Won, Closed Lost. If user says "moved to proposal" → map to "Solution" (the actual SF stage name).
- **`Amount` is always in USD** in Salesforce. If user provides CAD/EUR, note: "Converting to USD. Verify exchange rate."
- **Never clear a field.** If a field has content, append or update — do NOT blank it. Exception: user explicitly says "clear this field."
- **`Description` and `Reason_Details__c` are rich text.** But write plain text — rich text formatting doesn't render consistently across SF views.
- **Always include today's date** in next steps updates: "[2026-03-13] Called merchant, agreed to..." — timestamps make the field useful for history.

## Error Handling

| Scenario | Action |
|----------|--------|
| No write access (neither revenue-mcp nor Gumloop available) | Draft the update in copy-paste format. Include field API names: "Paste into SF: `Next_Step`: '{value}'" |
| Salesforce query fails | Retry once. If still fails: "SF API unavailable. Check auth/permissions. Here's what I would have written — paste manually." |
| Validation rule blocks write | Show the exact error message. Common: "Close date cannot be in the past" → suggest today or future date. "Stage cannot skip Deal Craft" → set intermediate stage first. |
| Record locked by another user | Note: "Record locked by {user}. Retry in 5 minutes, or ask them to release the lock." |
| Gumloop flow fails | Show error. Fall back to revenue-mcp. If both fail: manual paste format. |
| User asks to update a field that doesn't exist | Do NOT guess API names. Say: "I don't recognize field '{x}'. Common fields: Next_Step, Stage_Name, Amount, Close_Date, Description. Which one?" |
| User provides conflicting update (e.g., "set to Closed Won" but close date is 3 months away) | Flag: "Setting stage to Closed Won typically requires close date = today or past. Current close date is {date}. Update close date too?" |
| Opp was already updated by someone else since the READ | Show diff: "Field changed since I last read it. Current value: '{new}', you want: '{yours}'. Overwrite or merge?" Never silently overwrite. |
| User wants to bulk-update multiple opps | Process one at a time with confirmation per opp. Do NOT batch-write without per-record confirmation. "Updating 5 opps. Starting with {first}..." |
