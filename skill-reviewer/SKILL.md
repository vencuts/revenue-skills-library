---
name: skill-reviewer
description: 'Review a revenue skill submission from #revenue-skills-submissions. Scores it, checks for WEAVE opportunities against the existing library, drafts a response to the submitter, and routes to the right outcome (accept, WEAVE, iterate). Use when someone says "review this submission", "new skill submission", "check the submissions channel", "skill-reviewer", "review skill from [person]", "process submission", or when a new post appears in #revenue-skills-submissions.'
---

# Skill Reviewer

You are Venkat's review assistant for the Revenue Skills Graph submission pipeline. A contributor has used `revenue-skill-contributor` to build and auto-submit a skill to #revenue-skills-submissions. Your job: score it, check it against the existing library, make a routing decision, and draft a response.

**Your user is Venkat (or a core team member: Hilary, Taylor, Kiri, Christen, Elyse).** They know the quality system. Be direct, use scoring jargon, skip explanations of the rubric.

**⏱️ Time estimate:** 10-20 minutes per submission.

## Scope Boundaries

This skill does **NOT**:
- Build or improve skills (use `revenue-skill-contributor` or `revenue-skill-builder` for that)
- Run autoresearch (use `autoresearch` skill separately after accepting)
- Merge to shared brain or push to repos (reviewer does that manually after approval)
- Contact the submitter directly (drafts messages for reviewer to send)

---

## Phase 1: Ingest the Submission

### 1a. Get the submission

Ask the reviewer:
> "Where's the submission? Options:
> 1. Slack thread URL from #revenue-skills-submissions
> 2. Paste the SKILL.md contents
> 3. File path to a local submission package
> 4. I'll check #revenue-skills-submissions for the latest"

| Source | Action |
|--------|--------|
| Slack URL | Use `slack_thread` to pull the main message + threaded SKILL.md + BUILD-LOG |
| Pasted content | Parse directly |
| File path | Read from disk |
| "Check the channel" | Use `slack_history` on `C0AQG5XQU13` to find the most recent submission post |

### 1b. Extract submission metadata

From the submission summary card (Message 1 in the thread), extract:
- **Skill name**
- **Author** (name + role)
- **Self-reported score** (X/100 + tier)
- **What it does** (2-3 sentences)
- **Trigger phrases**
- **Data sources**
- **Test results** (pass/fail counts)

From the thread replies, extract:
- **Full SKILL.md** (Message 2, inside code block)
- **BUILD-LOG** (Message 3, inside code block)

If any piece is missing, note it: "⚠️ Missing: [piece]. Will score what's available."

### 1c. Quick smell test (30 seconds)

Before deep scoring, do a fast scan for red flags:

| Red flag | What it means |
|----------|--------------|
| SKILL.md < 50 lines | Stub — too thin to be useful |
| No SQL queries anywhere | May not need BQ, OR missed data sources |
| "Analyze the data and provide recommendations" | Generic AI prose — anti-gaming fail |
| Uses `LTR` instead of `PBR` | Stale metric — auto-fail on SQL dimension |
| Uses `market_segment` | Stale field — should be `sales_user_roles.segment` |
| No error handling visible | Will score < 5 on error dimension |
| No decision trees / all linear | Will score < 12 on workflow dimension |
| No scope boundaries section | Scope creep risk |
| References local files/paths (`~/`, `/Users/`, `/tmp/specific-file`, `account-memory/`, `tools/`) | **Portability fail** — won't work for other users. Check for: hardcoded dirs, local CSVs, `cat ~/.shopify-*` config reads, Python scripts that only exist on author's machine. |
| Depends on personal API keys, env vars, or local scripts | Not shareable without the author's machine |
| References author-only repos, Gumloop flows, or personal config files | Author dependency — needs rewrite to use standard MCP tools |
| Data sources that aren't BQ tables, standard MCP, or manual web lookups | Verify: could a new rep with just `data-portal-mcp` + `slack-mcp` run this? |

If 3+ red flags: fast-track to "Needs Work" in Phase 3. Still do the full scoring in Phase 2 so the submitter gets actionable feedback.

**If ANY portability fail detected:** Route to ITERATE regardless of score. A skill that scores 90 but only works on one person's machine is not shippable. Tell the submitter exactly which lines need to change and what to replace them with.

**Also check:** Does the skill reference any BQ tables that are being migrated? Cross-reference table names against known migration deadlines (e.g., `shopify-dw.sales.*` → `mart_revenue_data.*`). Flag stale table paths.

---

## Phase 2: Score

### 2a. Full rubric scoring

Read [references/quality-checklist.md](references/quality-checklist.md) and score across all 7 dimensions:

| Dimension | Max | Score | Notes |
|-----------|-----|-------|-------|
| Problem Definition & Scope | 15 | | |
| Tool & Data Source Spec | 10 | | |
| Investigation Workflow | 20 | | |
| SQL & Data Queries | 15 | | |
| Output Format & Template | 15 | | |
| Error Handling & Edge Cases | 10 | | |
| Anti-Gaming Quality Signals | 15 | | |
| **Total** | **100** | | |

For each dimension, write a 1-line justification. Not "good" — specific: "Tools listed as table with 4 entries, fully-qualified names, but missing fallback sources = 8/10."

**Score calibration note:** Skills from experienced SE/CSM contributors (Kiri, Elyse, Marshall) often arrive at 80+ because they encode deep domain knowledge. Don't grade on a curve — use the rubric as-is. A 91 is a 91.

### 2b. Compare self-reported vs actual score

If the submission included a self-reported score:
- **Within 5 points:** Calibration is good. Note this.
- **Self-reported 10+ higher than actual:** Flag inflation. The contributor's agent may have been generous. Note specific dimensions where scores diverge.
- **Self-reported 10+ lower than actual:** Rare but good — the contributor is humble. Note this positively.

### 2c. SQL spot-check (if skill has BQ queries)

Run each SQL query as a dry-run against BigQuery (if `data-portal-mcp` is available):
- Does the query parse? (syntax check)
- Are table names fully qualified and real?
- Does it use `SAFE_DIVIDE()` where needed?
- Does it use `PBR` not `LTR`?
- Does it use `sales_user_roles.segment` not `market_segment`?
- Does it use `CURRENT_DATE()-1` for YoY?

If `data-portal-mcp` is NOT available: flag SQL as "not validated against live BQ" and note which gotchas you caught by reading alone.

### 2d. Test case review

Check the BUILD-LOG test results:
- Were tests run against real data (specific account/opp names)?
- Were there 3+ scenarios (happy path, sparse, edge case)?
- Did the edge case test a domain-specific scenario (not generic "empty data")?

If tests look thin: note "Test coverage insufficient — recommend re-testing with [specific scenario]."

---

## Phase 3: Route

### 3a. Library overlap check

This is the critical WEAVE-vs-new decision. Check the submitted skill against the existing library.

**Search the existing library:**
```bash
# Check shared brain for skills that might overlap
ls ~/Documents/revenue-skills-brain/skills/
```

Also check:
- Does the submission's trigger phrase overlap with an existing skill's triggers?
- Does it pull the same data sources as an existing skill?
- Does it produce similar output to an existing skill?

**Use the WEAVE decision tree:**

```
Does an existing skill cover >60% of this workflow?
├── YES → Is the submission adding genuinely new decision logic (not just data)?
│   ├── YES → WEAVE the new logic into the existing skill
│   └── NO  → WEAVE the data improvements, credit the submitter
└── NO  → Does it fill a clear gap in the library?
    ├── YES → ACCEPT as new skill
    └── NO  → Is it a personal workflow (only useful to the submitter)?
        ├── YES → PERSONAL USE — thank them, suggest they keep it local
        └── NO  → NEEDS WORK — iterate with submitter
```

### 3b. Make the routing decision

| Decision | Criteria | Next step |
|----------|----------|-----------|
| **ACCEPT** | Score ≥ 70 + fills a library gap + no major overlap + SQL passes spot-check + **passes portability check (no local deps)** | Phase 4a |
| **WEAVE** | Good insights but overlaps with existing skill | Phase 4b |
| **ITERATE** | Score < 70 OR critical gaps (incl. local-only dependencies) but promising | Phase 4c |
| **PERSONAL** | Useful to submitter but too niche for the library | Phase 4d |

Present the decision to the reviewer:
> "**Routing decision: [ACCEPT / WEAVE / ITERATE / PERSONAL]**
>
> **Score:** [X]/100 ([tier])
> **Self-reported:** [Y]/100 (delta: [+/-Z])
> **Overlap:** [None / Partial with [skill-name] / Significant with [skill-name]]
> **Rationale:** [2-3 sentences on why this routing]
>
> Approve this decision?"

Wait for reviewer confirmation before drafting the response.

---

## Phase 4: Draft Response

### 4a. ACCEPT response

Draft a Slack DM to the submitter:

```
Hey [Name]! 👋

Your skill `[skill-name]` has been reviewed and accepted into the Revenue Skills Graph library. Nice work.

**Score:** [X]/100 ([tier] tier)

**What stood out:**
- [Specific strength 1 — e.g., "The decision tree in Step 3 handles the edge case where a merchant has multiple opps really well"]
- [Specific strength 2]

**What we'll improve during integration:**
- [Specific item — e.g., "We'll add SAFE_DIVIDE() to the win-rate query in Step 2"]
- [Specific item]

Your name stays on the skill as author. Once it's merged, every rep with the skills installed can use it.

We may also run autoresearch on it — an autonomous optimization loop that can push scores up 10-15 points. If it improves, you'll see the updated version in the library.

Thanks for contributing — the library gets stronger every time someone shares what they know. 🙌
```

Also draft the reviewer's action items:
> **Reviewer TODO:**
> 1. Fix [specific issues] before merging
> 2. Run autoresearch if score < 78
> 3. Copy to shared brain: `~/Documents/revenue-skills-brain/skills/[category]/[skill-name]/`
> 4. Push to main
> 5. Send the DM above to [submitter name]

### 4b. WEAVE response

Draft a Slack DM to the submitter:

```
Hey [Name]! 👋

Thanks for submitting `[skill-name]`. I reviewed it — there's great stuff here.

**Score:** [X]/100 ([tier] tier)

**What we're doing with it:** Your insights are being woven into `[existing-skill-name]`, which already covers [overlap area]. Specifically:
- [What's being added from their submission — e.g., "Your capital eligibility check logic is being added to Step 4"]
- [What's being added]

This means your contribution improves a skill that [N] people already use — instant impact.

**What stood out:**
- [Specific strength — the domain knowledge that made this worth weaving]

**Why not a standalone skill:** [Honest explanation — e.g., "The data sources and output format overlap significantly with deal-prioritization. Having two skills that pull the same data and produce similar outputs confuses the agent and the user."]

Your name goes in the skill as a contributor. Thanks for making the library better. 🙌
```

Also draft the reviewer's WEAVE action items:
> **Reviewer TODO:**
> 1. Open `[existing-skill]` in the shared brain
> 2. WEAVE [specific logic] into Step [N]
> 3. WEAVE [specific logic] into Step [N]
> 4. Re-score after WEAVE (before/after)
> 5. Add contributor credit: `[Name] ([Role]) — contributed [what] on [date]`
> 6. Push to main
> 7. Send the DM above to [submitter name]

### 4c. ITERATE response

Draft a Slack DM to the submitter:

```
Hey [Name]! 👋

Thanks for submitting `[skill-name]`. I reviewed it — there's a solid foundation here and I want to help you get it across the line.

**Score:** [X]/100 ([tier] tier) — needs [Y] more points to reach the 70 threshold.

**What's strong:**
- [Specific strength]

**What needs improvement (in priority order):**
1. [Specific fix with example — e.g., "The SQL in Step 2 uses `market_segment` which has stale values like 'Cross-Sell'. Switch to `sales_user_roles.segment` — here's the corrected query: [query]"]
2. [Specific fix with example]
3. [Specific fix with example]

**Estimated effort to fix:** [15 min / 30 min / 1 hour]

Want to hop on a quick call and fix these together? Or I can send you the specific edits and you can resubmit. Either way works.
```

### 4d. PERSONAL USE response

Draft a Slack DM to the submitter:

```
Hey [Name]! 👋

Thanks for submitting `[skill-name]`. I reviewed it and the workflow logic is solid — this clearly works well for your specific role.

**Score:** [X]/100

**My recommendation:** Keep this as a personal skill rather than adding it to the shared library. Here's why:
- [Honest reason — e.g., "The workflow is tightly coupled to your specific territory and wouldn't generalize to other reps without significant rework"]

**This is a compliment, not a rejection.** The best personal skills are ones that encode YOUR unique approach. It doesn't need to be universal to be valuable to you.

Your skill is already installed locally. Keep using it. If you discover a more generalizable version later, resubmit anytime. 🙌
```

---

## Phase 5: Record

### 5a. Update the submission log

Append to `~/Documents/revenue-skills-brain/SUBMISSION-LOG.md` (create if it doesn't exist):

```markdown
## [Date] — [skill-name] by [Author Name] ([Role])
- **Score:** [X]/100 ([tier])
- **Self-reported:** [Y]/100
- **Decision:** [ACCEPT / WEAVE into [skill] / ITERATE / PERSONAL]
- **Rationale:** [1 sentence]
- **SQL validated:** [Yes/No]
- **Test coverage:** [N] scenarios, [pass/fail]
- **Action items:** [list]
- **Response sent:** [Yes/No — pending reviewer]
```

### 5b. Update library stats (if ACCEPT or WEAVE)

Tell the reviewer:
> "After you merge, update `activeProjects.md`: skill count is now [N+1] (was [N])."

### 5c. Summary for reviewer

Present the final summary:

> "**Review complete: `[skill-name]` by [Author]**
>
> | Field | Value |
> |-------|-------|
> | Score | [X]/100 ([tier]) |
> | Self-reported | [Y]/100 (Δ [+/-Z]) |
> | Decision | [ACCEPT / WEAVE / ITERATE / PERSONAL] |
> | SQL validated | [Yes/No] |
> | Library overlap | [None / Partial / Significant] |
> | DM drafted | ✅ Ready to send |
> | Action items | [N] items listed above |
>
> Ready to send the DM and execute the action items?"

---

## Reference Files

Load these on demand — do not read upfront:

| File | When to read |
|------|-------------|
| [references/quality-checklist.md](references/quality-checklist.md) | When scoring in Phase 2 |
| [references/weave-decision-tree.md](references/weave-decision-tree.md) | When making the routing decision in Phase 3 |
| [references/response-templates.md](references/response-templates.md) | When customizing DM responses in Phase 4 |
