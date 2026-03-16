---
name: deal-followup
description: Generate post-meeting follow-up emails with context pulled from call transcripts, meeting notes, and deal history. Researches open questions with shareable links, includes relevant apps, and formats for copy-paste into Gmail. Use when asked to "write follow-up", "draft follow-up email", "follow up after [meeting]", "post-call email", "send recap to [merchant]", or "demo follow-up". Works for AEs, SEs, and CSMs after any external meeting.
---

# Deal Follow-Up

Generate post-meeting follow-up emails by pulling context from transcripts and researching open questions. **Plain text in a code block is always the default** — copy-paste ready.

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `gdrive_search` / `gcal_events` | Find transcript doc or meeting recording | Ask user to paste key points or provide doc URL |
| `query_bq` | Salesloft transcript from BigQuery; UAL account verification | Skip account verification; draft from user-provided context |
| `perplexity_search` | Research open questions, find Help Center / shopify.dev links | Note inline: "I'll follow up on [topic] separately" |
| `vault_search` | Product updates, internal feature status for answering commitments | Provide public links only; flag that internal context wasn't checked |

## Domain Rules

- **Never include internal-only links** (Vault, Slack, internal dashboards) in merchant-facing emails. Every URL must be publicly accessible.
- **Never fabricate App Store links.** If you can't verify the app URL, write: "I'll send the link separately" instead of guessing `apps.shopify.com/...`.
- **"Follow up" emails must actually follow up.** If the transcript shows 3 open questions, answer all 3. Missing one signals the merchant wasn't heard.
- **Stop at the sign-off.** End at "Best," or "Thanks," — never add the user's name, title, or company. The email client handles that.
- **Match the meeting's energy.** If the call was casual, the follow-up should be too. If it was formal (procurement team), match that tone. Do NOT default to corporate stiffness.

---

## Workflow

### Step 0: Data Integrity Pre-Flight

If following up on a specific deal/account, run `data-integrity-check`. If the account has duplicates, ensure you're pulling context from the correct record. If territory owner is inactive, the follow-up may need to CC the actual coverage rep, not the stale SF owner.

### Step 1: Get the Transcript

Determine source (ask if unclear):
- **Google Doc URL** → extract doc ID, read via `gworkspace`
- **Salesloft conversation** → query BigQuery for transcript + summary
- **Fellow meeting** → query via `fellow-mcp`
- **User pastes text** → use directly

Extract from transcript:
- **Open questions** the seller committed to follow up on
- **Key topics discussed** and what resonated with the merchant
- **Pain points** raised
- **Decisions made** and items shelved
- **Next steps** agreed in the call
- **Attendee names** and roles
- **Merchant context** (industry, requirements, concerns)

### Step 1b: Verify Account Context (UAL Lookup)

If the merchant's company name or domain is known, validate account details via the Unified Account List. This ensures follow-up references correct account ownership and avoids sending to a merchant owned by a different rep.

```sql
SELECT
  COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
  COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
  territory_name,
  account_id AS sf_account_id
FROM `sdp-prd-commercial.mart.unified_account_list`
WHERE LOWER(COALESCE(domain, domain_sf, domain_3p, domain_1p))
      LIKE CONCAT('%', LOWER(@merchant_domain), '%')
LIMIT 5
```

Use this to:
- Confirm account name spelling for the email salutation
- Verify the AE sending the follow-up actually owns this account
- Pull territory context if relevant to the conversation

### Step 2: Research Open Questions

For each follow-up commitment:
1. **Help Center** — Search for public documentation (shareable links)
2. **shopify.dev** — Technical details if needed
3. **App Store** — Search `apps.shopify.com/search?q=[term]` for relevant apps
4. Web search for current capabilities

**Every answer must include at least one shareable link.**

### Step 3: Identify Relevant Apps (if applicable)

4-6 apps that directly address discussed requirements:
- Shopify-native apps where relevant (Flow, Search & Discovery, Checkout Blocks)
- Each app: name, App Store link, one-line why it's relevant to THIS merchant
- Don't pad with generic filler — only include apps that match their needs

### Step 4: Compile Next Steps

From transcript, restate the agreed actions:
- What you (seller) will do and by when
- What they (merchant) will do and by when
- Any scheduled follow-up meetings

### Step 5: Generate Email

**Default output: plain text in a code block.**

Subject line OUTSIDE the code block. Body INSIDE (triple backticks, no language tag).

```
Subject: [Meeting Title] Follow-Up — [Key Topic]
```

```
Hi [Name],

Thanks for [the call/demo/session] today — [one sentence connecting to what resonated].

[OPEN QUESTIONS SECTION — only if there were follow-up commitments]

You asked about [topic]. [Answer with context]. Here's the documentation:
- [Link to help center / shopify.dev / app store]

[Repeat for each open question]

[KEY TOPICS SECTION — only if valuable to reinforce]

[Brief reinforcement of 1-2 key topics that resonated, connected to their business outcome]

[APPS SECTION — only if relevant apps were discussed or would add value]

A few tools worth exploring based on what we discussed:
- [App Name] — [one-line relevance] ([App Store link])
- [App Name] — [one-line relevance] ([link])

[NEXT STEPS — always include]

For next steps:
- [Action — owner — timeline]
- [Action — owner — timeline]

[Sign-off — match the meeting's tone. Stop at "Best," or "Thanks," — no name/signature]
```

**Rules:**
- 15-20 lines max. Concise, not comprehensive.
- Every link must be a real, shareable URL (not internal-only)
- No markdown formatting inside the code block. Use `-` for bullets.
- Replies (not first contact): no subject, no signature, match their formality
- No emojis unless the conversation was casual

### Step 6: Optional HTML Version

Only if user explicitly asks for "branded" or "HTML" email:
- Use professional template with dark header, `.topic` blocks, `.app-card` blocks
- Gmail-safe: no flexbox/grid, single-column, inline styles
- Save to file and instruct: `Cmd+A → Cmd+C in browser, paste into Gmail`

See `references/email-template.md` for full HTML template.

---

## Tone Framework

1. Check user's personal config / preferences for tone
2. If not found → default: direct, factual, merchant-first
3. **Partnership tone** — consultative, collaborative
4. **"We" language** — not "I recommend" but "we discussed"
5. Focus on enabling merchant success through the platform
6. Professional warmth without being fluffy

---

## Quality Checklist

- [ ] All open questions from transcript answered with shareable links
- [ ] Every answer has at least one link (Help Center, shopify.dev, App Store)
- [ ] Apps are relevant to THIS merchant (not generic)
- [ ] Next steps match what was agreed (don't invent new ones)
- [ ] Tone matches the meeting's energy
- [ ] Under 20 lines
- [ ] No internal-only links or information exposed

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Transcript unavailable / not found | Ask user to paste key points or meeting summary. Do NOT draft from imagination. |
| Research fails (search unavailable) | Note inline: "I'll follow up on [topic] separately." Never leave a commitment unanswered without flagging it. |
| No relevant apps for this merchant | Skip the apps section entirely. Do NOT pad with generic apps to fill space. |
| User says "make it shorter" | Cut to: greeting + open questions + next steps only. Remove reinforcement and apps sections. |
| UAL shows account owned by different rep | Flag to user: "UAL shows this account is owned by {other_rep}. Verify before sending follow-up — this may be a territory issue." |
| Multiple transcripts found for same meeting | Ask user to confirm which one. If timestamps match: pick the longest (most complete). |
| Transcript is auto-generated with errors | Work with what's there. Flag: "Transcript may have auto-transcription errors — verify names and technical terms before sending." |
| Open question from transcript can't be answered | Don't skip it. Include: "You asked about [X] — I'm confirming details and will follow up by [date]." |
