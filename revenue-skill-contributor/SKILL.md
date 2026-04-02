---
name: revenue-skill-contributor
description: 'Build or improve a revenue skill and submit it to the Revenue Skills Graph team for review. Designed for anyone — reps, RevOps, SEs, CSMs — who wants to contribute a skill or improve an existing one. Guides through the full quality process including scoring, testing with real data, and optional autoresearch. Use when someone says "I want to build a skill", "submit a skill", "contribute a skill", "improve my skill for the team", "I have a skill to share", "revenue skill contribution", "skill for the graph", "submit to Venkat", or wants to create a skill that could benefit the wider revenue org.'
---

# Revenue Skill Contributor

You are guiding someone through building or improving a revenue skill to a high quality bar, then packaging it for submission to the Revenue Skills Graph team.

**Your user is likely NOT technical.** They know their workflow deeply but may not know SQL, BigQuery, SKILL.md format, or agent architecture. You do ALL the technical work. They describe; you build.

**Key principle:** The user's domain expertise is the raw material. Your job is to turn it into a structured, testable, scorable skill that meets the team's quality standard.

**⏱️ Time estimate:** Full process takes 45-90 minutes. Phase 1 (build/improve): 20-40 min. Phase 2 (test + score): 15-30 min. Phase 3 (scoring decision): 5 min. Phase 4 (package): 5-10 min. Autoresearch (optional): 30-60 min additional.

**MCP dependencies:** This skill works best with `data-portal-mcp` (BigQuery access) and `slack-mcp` (Slack search). If neither is available, the skill still works — SQL steps become "show and verify" instead of "run directly."

## Scope Boundaries

This skill does **NOT**:
- Compare submissions against the existing 53 skills (the core team does that)
- Make WEAVE vs new-skill decisions (the core team decides)
- Handle River integration or deployment
- Require any prior experience with SKILL.md format, SQL, or git
- Need any specific skills installed (all capabilities are built in — installed skills are power-ups, not requirements)

---

## Installed Skills to Leverage

If these skills are available in your environment, **use them** — they are purpose-built for skill quality:

| Skill | When to invoke | What it does |
|-------|---------------|-------------|
| `skill-architect` | Phase 1B (improve existing) | Use its **Review Mode** checklist to audit an uploaded skill |
| `skill-augmentation` | Phase 1B (improve existing) | Research domain gaps using all available tools (Slack, Vault, BQ, web) |
| `skill-creator` | Phase 2 (quality loop) | Run test cases, generate eval viewer, compare with/without |
| `skill-evaluator` | Phase 2 (quality loop) | Formal eval suite: auto-grade typed assertions, benchmark pass rates |
| `skill-improver` | Phase 2 (quality loop) | Mine session history for failures, diagnose trigger issues |
| `autoresearch` | Phase 3B only | Autonomous improvement loop |

**If a skill above is NOT installed:** fall back to the inline instructions in this skill. The inline version covers the same ground — just without the automation scripts.

---

## Phase 0: Orient

### 0a. Welcome and explain

Tell the user:

> "I'll help you turn a workflow you know into a structured skill that an AI agent can follow.
>
> When we're done, you can share it with the Revenue Skills Graph team — they maintain 53+ skills across the revenue org.
>
> Three paths: (1) **Build from scratch** — describe your workflow, I build it. (2) **Improve existing** — you have a draft, I audit it. (3) **Adapt a tool** — turn a script/spreadsheet/Gumloop flow into a skill.
>
> This usually takes about an hour. Which path?"

### 0b. Route

| User says | Go to |
|-----------|-------|
| "Build from scratch" / describes a workflow | [Phase 1A: Build](#phase-1a-build-from-scratch) |
| "I have a skill" / pastes or points to a SKILL.md | [Phase 1B: Improve](#phase-1b-improve-existing) |
| "I have a script/spreadsheet/Gumloop flow/tool" | [Phase 1C: Adapt](#phase-1c-adapt-existing-tool) |

---

## Phase 1A: Build from Scratch

### Step 1: Interview

Ask these questions one at a time. Do NOT ask them all at once — it overwhelms non-technical users. Wait for each answer before asking the next.

1. **"What's the task?"** — What do you do, step by step? Walk me through it like I'm shadowing you.
2. **"How often?"** — Daily? Weekly? When triggered by an event?
3. **"What data do you look at?"** — Don't ask about "data sources." Ask: "What do you check? Where do you go? What tools do you open?" (You translate to BQ tables later — but many sources won't be in BQ, and that's fine.)
4. **"What tools does your AI agent have?"** — Ask: "Do you have any MCP connections set up? (Slack, BigQuery/data-portal, Vault, etc.)" This determines what the skill can automate vs what stays as a manual lookup step.
5. **"What do you produce?"** — A Slack message? A doc? A decision? Meeting prep? A Salesforce update?
6. **"What goes wrong?"** — When does this task fail? What mistakes do new people make?

### Step 1b: Go Deeper (DO NOT SKIP)

The first answers are always surface-level. You MUST probe deeper on at least questions 1 and 3. Non-technical users describe "what" they do, not "how" they decide.

**Depth probes** (use at least 2):
- "You said you check [tool]. What SPECIFICALLY on that screen? Which fields?"
- "When you see [signal], what do you do differently?"
- "If you trained a new rep, what would they get wrong the first week?"
- "Are there signals you check that most other reps don't? Secret sauce?"

**Interview completeness checklist** (all must be checked before moving to Step 2):
- [ ] Got specific field/screen names (not just "I check Copilot")
- [ ] Got at least 2 decision points with explicit criteria ("if X then Y")
- [ ] Got at least 1 edge case or failure mode with a specific example
- [ ] Got the actual output format (template, mental checklist, Slack message, etc.)
- [ ] Know the frequency (daily/weekly/event-triggered)
- [ ] Know what MCP tools the user's agent has

If any box is unchecked, keep probing. If user says "I don't know" — that's valuable. The intuitive stuff is exactly what needs to be made explicit. Rephrase and try again.

### Step 2: Translate to skill architecture

Using the user's answers:

1. **Map data sources.** Read [references/table-quick-reference.md](references/table-quick-reference.md) to find BQ tables. If the user says "Salesforce" → that's `shopify-dw.rpt_salesforce_banff.*`. If they say "call transcripts" → that's `sales_calls`.

   **For sources NOT in BQ** (Copilot, Borage, Services Internal, Abacus, merchant websites, Looker, external APIs): these become **manual lookup steps** or **MCP-powered steps** in the skill. The skill can still guide the agent to check these — just not with SQL. Example:
   ```
   ### Step 2: Check Borage for real-time offers
   Open Borage (bourgeois.shopify.io) and search by merchant name.
   Look for: current offers, APR, factor rate, past capital history.
   If Borage is unavailable, note: "Real-time offer data unavailable — using Copilot data (24hr delay)."
   ```
   Tell the user what you found:
   > "You mentioned you check [X]. [Y] of your sources are in BigQuery — I can write queries for those. [Z] sources (like [tool names]) aren't queryable by the AI, so I'll write them as guided manual steps or MCP lookups."

2. **Structure the workflow as numbered steps with decision points.** Not linear — real workflows have "if X then Y, otherwise Z." Capture those branches.

3. **Identify the output format.** Match it to what the user actually needs (Slack-formatted? Bullet summary? Before/after comparison?).

4. **Write error handling INTO each step** (WEAVE pattern — don't add error handling as a separate section at the bottom. Each step should say what to do when data is missing or a query fails.)

### Step 3: Draft the SKILL.md

Follow this structure:

```markdown
---
name: [skill-name]
description: '[What it does]. Use when [trigger phrases the user would say].'
---

# [Skill Name]

[One sentence: what this skill does and who it's for.]

## When to Use
[2-3 bullet points describing trigger scenarios]

## What You Need
[Tools/data/access required — be specific]

## Workflow

### Step 1: [Action verb + what]
[Instructions with decision tree if applicable]
[SQL query if needed — fully qualified table names]
[Error handling: "If [X] is empty/fails, do [Y]"]

### Step 2: ...
[Continue for each step]

## Output Format
[Exact template of what the skill produces]

## Scope Boundaries
[What this skill does NOT do — prevents scope creep]
```

**Follow the quality patterns in [references/quality-checklist.md](references/quality-checklist.md)** — especially: tools as TABLE, 8+ WEAVE'd error scenarios, decision trees, domain vocab (PBR/SAFE_DIVIDE/sales_user_roles), fully-qualified table names, negative boundaries, conditional output.

**Anti-AI writing rule:** The skill you produce must use specific domain language, not generic AI prose. If any step says "analyze the data and provide recommendations" — that's boilerplate and will score 3/15 on Anti-Gaming. Replace with exact checks, thresholds, and decisions.

Show the draft to the user:
> "Here's the first draft. Read through it — does it match how you actually do this work? What's wrong or missing?"

Iterate based on their feedback. **This is the most important step.** The user is the domain expert. Trust their corrections.

### Early exit

If the user says "this is too much" or "I'm done" at any point:
> "No problem — I'll save everything we have so far. Your skill is at [current state]. You can come back anytime and pick up where we left off, or send what we have to the team and they'll help finish it."

Save the current SKILL.md draft + any test results to a `[skill-name]-wip/` directory. Install whatever exists locally so the user gets immediate value.

**✅ Phase 1A Gate Checklist** (verify ALL before moving to Phase 2):
- [ ] SKILL.md has `name` and `description` with 3+ trigger phrases
- [ ] Workflow has numbered steps (not prose paragraphs)
- [ ] At least 1 decision tree ("if X then Y, otherwise Z")
- [ ] Data sources mapped: BQ tables with fully-qualified names OR manual lookup steps
- [ ] Output format section with concrete template (not "summarize findings")
- [ ] Scope Boundaries section ("This skill does NOT...")
- [ ] Error handling WOVEN into at least 3 workflow steps (not a section at the bottom)
- [ ] No generic AI prose ("analyze the data" → replaced with specific checks)
- [ ] User has reviewed and approved the draft

→ All checked? Go to [Phase 2: Quality Loop](#phase-2-quality-loop)

---

## Phase 1C: Adapt Existing Tool

The user has an existing script, spreadsheet, Gumloop flow, Quick site, or other tool they want to turn into a skill.

### Step 1: Understand the tool

Ask:
1. "What does your tool do? Walk me through it."
2. "What data does it pull and from where?"
3. "What output does it produce?"
4. "Can you paste or describe the key logic?" (You probably can't access their tool directly — the user is the source of truth.)

### Step 2: Map to skill architecture

- Which parts can the AI agent do via BQ/MCP? → Automate these
- Which parts need external tools? → Manual lookup steps
- What's the workflow? → Structure as decision tree
- What's the output? → Map to skill output format

Tell the user:
> "Here's how your [tool] maps to a skill: [X] parts can be automated, [Y] stay as guided steps. Does this look right?"

### Step 3: Build

Continue to Phase 1A, Step 3 (Draft the SKILL.md) with the mapped architecture.

**✅ Phase 1C Gate Checklist:**
- [ ] Original tool's logic is captured (user confirmed)
- [ ] Automated vs manual steps clearly separated
- [ ] SKILL.md draft follows Phase 1A structure
- [ ] User approved the mapping

→ All checked? Go to [Phase 2: Quality Loop](#phase-2-quality-loop)

---

## Phase 1B: Improve Existing

### Step 1: Read the skill

Tell the user:
> "Great — let me take a look at what you have. Can you paste the SKILL.md contents here, share a file path, or point me to a URL?"

Wait for them to share it.

Read it completely. Build a mental model of:
- What it claims to do
- What tools/data it uses
- How the workflow flows
- Where it's thin, vague, or missing error handling

### Step 2: Audit against quality standards

**If `skill-architect` is installed:** invoke its **Review Mode** on the uploaded SKILL.md. It runs a comprehensive checklist covering discovery, effectiveness, efficiency, and structure.

**If not installed**, score manually against these criteria (from [references/quality-checklist.md](references/quality-checklist.md)):

| Area | Check | |
|------|-------|-|
| Problem | Clear scope + trigger phrases? | |
| Tools | Listed as table? Fully qualified table names? | |
| Workflow | Decision trees? Not just linear steps? | |
| SQL | Real queries? Tested against BQ? | |
| Output | Conditional template? Verdict-first? | |
| Errors | 8+ scenarios woven into steps? | |
| Anti-gaming | Domain vocab? Negative boundaries? Specific not vague? | |

### Step 3: Research domain gaps

**If `skill-augmentation` is installed:** invoke it — it analyzes gaps, plans research across available tools (Slack, Vault, BQ, web), filters through a 4-filter chain (behavior change, novelty, specificity, token cost), and proposes integration points.

**If not installed**, research manually with this procedure:

1. **Table discovery:** Read [references/table-quick-reference.md](references/table-quick-reference.md). For each data source the user mentioned, check: is there a BQ table they didn't know about? Is there a better table than the one they used? (e.g., `sales_calls` includes Google Meet since Mar 2026 — most people don't know this.)
2. **SQL gotcha check:** Scan their SQL (if any) for known mistakes: LTR instead of PBR? `market_segment` instead of `sales_user_roles.segment`? Raw division instead of `SAFE_DIVIDE()`? `CURRENT_DATE()` instead of `CURRENT_DATE()-1`? `is_inbound` instead of `replied_to_email_id` for reply rate?
3. **Error scenario inventory:** Walk through each workflow step and ask: "What happens if this data is empty? What if the query returns zero rows? What if the tool is down?" Aim for 8+ scenarios.
4. **Best practice gap check:** Compare to the 72→78 checklist in [references/quality-checklist.md](references/quality-checklist.md) — tools as TABLE? WEAVE'd errors? Conditional output? Decision trees? Negative boundaries?

### Step 3b: Verify research with user (DO NOT SKIP)

Before presenting improvements, verify your research findings with the user:
> "I researched your skill's domain and found some things. Let me check if these match your reality:"
> - "I found [tool/table/field]. Do you actually use this? How?"
> - "I see [pattern]. Is that how it works in practice?"
> - "Does [edge case] happen? How often?"

The user knows their workflow better than any research. Discard findings they say are wrong. Probe deeper on findings they confirm.

### Step 4: Present findings

Tell the user:
> "I've reviewed your skill and researched the domain. Here's what I found:
>
> **Strong:**
> - [specific things done well]
>
> **Needs improvement:**
> - [specific gap 1 — e.g., "No error handling for when the opp has no calls"]
> - [specific gap 2 — e.g., "SQL uses wrong table — market_segment is deprecated, use sales_user_roles.segment"]
> - [specific gap 3]
>
> **Domain research discoveries:**
> - [data source they didn't know about — e.g., "sales_calls now includes Google Meet transcripts (since Mar 2026) — your skill only checks SalesLoft"]
> - [pattern from the skill library — e.g., "loss-intelligence uses a 3-tier matching system for call transcripts that you could adopt"]
> - [best practice — e.g., "Top skills use SAFE_DIVIDE() — yours has raw division that will crash on zero"]
>
> Want me to make these fixes?"

### Step 5: Fix and iterate

Make the improvements. Show before/after for each change. Get user approval on each.

Apply key corrections from our 53-skill library: `SAFE_DIVIDE()`, PBR not LTR, `sales_user_roles.segment` not `market_segment`, `CURRENT_DATE()-1` for YoY, 3-tier call matching, graceful degradation on missing data. See [references/quality-checklist.md](references/quality-checklist.md) for the full list.

**✅ Phase 1B Gate Checklist:**
- [ ] Audit completed (skill-architect Review Mode or manual 7-area table)
- [ ] Domain research done (skill-augmentation or manual 4-step procedure)
- [ ] Research findings verified with user (Step 3b)
- [ ] All identified SQL gotchas fixed (PBR, SAFE_DIVIDE, segment, dates)
- [ ] Error handling count: ≥8 scenarios woven into steps
- [ ] User approved all improvements

→ All checked? Go to [Phase 2: Quality Loop](#phase-2-quality-loop)

---

## Phase 2: Quality Loop

### 2a. Test with real data

**If `skill-creator` is installed:** use its test case framework — it spawns parallel with-skill and without-skill runs, generates an eval viewer, and captures timing data. Follow its Step 1–5 sequence.

**If `skill-evaluator` is installed:** use it to create formal evals in `evals/evals.json` with typed assertions (contains, regex, not_contains). It runs deterministic grading and benchmark aggregation.

**If neither is installed**, run tests manually:

Tell the user:
> "Now I need to test this against real data. Can you give me a specific account, deal, or opp you know well? One where you already know what the correct answer should be — so you can tell me if the skill gets it right."

Run the skill's full workflow against their chosen entity. **If you have data-portal MCP access, run the BQ queries directly.** If not, show the SQL and ask the user to verify: "Here's the query I'd run. Can you confirm this looks right for [entity]?" For non-BQ steps, walk through them manually with the user.

Show the complete output. Ask:
- "Are these facts correct?"
- "Would you actually use this output?"
- "Anything missing or wrong?"

Fix anything they flag. Repeat until they say "yes, that's right."

**Example of what a finished skill looks like** (abbreviated — real skills are longer):
```markdown
---
name: capital-hot-leads
description: 'Identify and prioritize lending hot leads from Copilot signals. Use when rep says "who should I call first", "hot leads", "morning priorities".'
---
# Capital Hot Leads
Identify merchants showing capital interest signals, prioritize by urgency.

## Workflow
### Step 1: Pull credit tab visitors (7-day window)
Query `shopify-dw.mart_revenue_data.sales_calls`... [SQL here]
If no results: "No hot leads in the last 7 days. Check 14-day window."

### Step 2: Cross-reference with capital eligibility
Check Copilot > Shops tab > recommendation insights...
If merchant is ineligible: skip, note reason.
If newly eligible (was ineligible last week): flag as HIGH PRIORITY.

## Output
**[X] hot leads found** (sorted by urgency)
| Merchant | Signal | Eligibility | Priority |
```

**Generate at least 3 test scenarios** (don't settle for 1):
1. **Happy path** — full data available
2. **Sparse data** — missing calls, missing emails, incomplete record
3. **Edge case** — specific to THIS skill's domain. Ask the user: "What's a weird situation that would trip up a new rep?" Generic edge cases aren't enough — domain-specific ones matter (e.g., campaign tracking: paused vs new activation; lending: merchant re-eligible after 51% repayment).

Run all 3. Fix any failures. Show before/after for each fix.

### 2b. Score the skill

Read [references/quality-checklist.md](references/quality-checklist.md). Score across all 7 dimensions:

| Dimension | Max | Score |
|-----------|-----|-------|
| Problem Definition & Scope | 15 | |
| Tool & Data Source Spec | 10 | |
| Investigation Workflow | 20 | |
| SQL & Data Queries | 15 | |
| Output Format & Template | 15 | |
| Error Handling & Edge Cases | 10 | |
| Anti-Gaming Quality Signals | 15 | |
| **Total** | **100** | |

Show scores. Explain what each means in plain language.

### 2c. Quick self-check

Before proceeding, do a sanity check (don't use OODA jargon with the user):
1. Does the skill match what the user actually described, or did it drift?
2. What's the single weakest area in the scoring?
3. Fix that one area. Show before/after score.

Ask the user: "Quick check — does this skill still match your actual workflow? Anything feel off?"

### 2d. Iterate (don't settle)

**If `skill-improver` is installed:** use its full iteration loop — it identifies the weakest dimension, makes one category of change per iteration, re-runs evals, and tracks history.

If score < 70: identify the weakest dimension, fix it, re-score. **Max 5 iterations.**
If score ≥ 70 but < 78: tell the user which specific changes would push to Excellent tier. Offer to make them. After user decides (accept or decline), proceed to Phase 3.
If score ≥ 78: proceed to Phase 3.

**Every exit from Phase 2 must go to Phase 3.** Even if stuck after 5 iterations — tell the user "This is a solid v1 at [score]. The core team has advanced tools (autoresearch, blind eval) that can push it further." Then proceed to Phase 3.

**Between each iteration, ask the user:**
> "The weakest area is [dimension] at [score]. Here's what I'd change: [specific edit]. This is based on [pattern from top skills / specific gotcha]. Should I apply it?"

Do not auto-fix without explaining WHY. The user learns the quality standard through the iteration, not just the final product.

**✅ Phase 2 Gate Checklist** (verify ALL before moving to Phase 3):
- [ ] Tested against real data with user-known entity (user confirmed output is correct)
- [ ] 3 test scenarios run: happy path ✓, sparse data ✓, domain-specific edge case ✓
- [ ] All test failures fixed and re-verified
- [ ] Scored across all 7 rubric dimensions (scores recorded)
- [ ] Self-check done: skill still matches user's actual workflow
- [ ] Score is ≥70 OR 5 iterations exhausted with honest "v1" message
- [ ] User confirmed "this looks right" after final iteration

→ All checked? Go to Phase 3.

---

## Phase 3: Scoring Track Decision

**Before presenting options, check prerequisites for Track B:**
```bash
which git 2>/dev/null && echo "git: OK" || echo "git: NOT FOUND"
ls ~/Documents/revenue-skills-brain/.git 2>/dev/null && echo "brain repo: OK" || echo "brain repo: NOT FOUND"
```
If git or the brain repo aren't available, **skip Track B entirely** — just present Track A.

Tell the user (include the tier name so they can interpret the score):

> "Your skill scores [X]/100 — that's **[tier name]** tier.
> *(Stub <50 | Functional 50-69 | Good 70-77 | Excellent 78+)*
>
> There are two ways to go from here:
>
> **Option A: Submit as-is** — I'll package your skill with the score and test results. The core team (Venkat's group) will run their full scoring process including autoresearch and blind evaluation. This is the easier path.
>
> **Option B: Run autoresearch yourself** — This is an autonomous improvement loop where the AI repeatedly tweaks your skill, scores it, keeps improvements, and reverts failures. It can push scores significantly higher. ⚠️ **Fair warning: this requires some technical comfort** — you'll need to understand git branches, watch experiment logs, and review blind test results. But I'll walk you through every single step. If you're up for it, the skill will arrive at the team's door in much better shape.
>
> Which would you prefer?"

| User chooses | Go to |
|-------------|-------|
| Option A (submit as-is) | [Phase 4: Package & Submit](#phase-4-package--submit) |
| Option B (autoresearch) | [Phase 3B: Autoresearch](#phase-3b-autoresearch-guided) |

---

## Phase 3B: Autoresearch (Guided)

⚠️ **Only if user explicitly chose this path.**

Read [references/autoresearch-walkthrough.md](references/autoresearch-walkthrough.md) for the full step-by-step guide. Follow it exactly — every command is spelled out.

**Flow:** git branch → blind test cases (you write, user validates) → autoresearch.md + .sh → baseline → loop (improve → score → keep/revert) → review results → keep or revert.

**User's role:** Validate test cases. Spot-check outputs. Say when to stop.

**✅ Phase 3B Gate Checklist:**
- [ ] Blind test cases created and user-validated
- [ ] Baseline score recorded
- [ ] Autoresearch loop ran (N iterations logged)
- [ ] Before/after scores shown to user
- [ ] User confirmed: keep improvements OR revert to pre-autoresearch
- [ ] Final skill version committed to git

→ All checked? Go to [Phase 4: Package & Submit](#phase-4-package--submit)

---

## Phase 4: Package & Submit

### 4a. Generate the submission package

Create a directory with:

```
[skill-name]-submission/
├── SKILL.md                    # The final skill
├── BUILD-LOG.md                # What was built, tested, scored, discovered
├── test-results/               # Real data test outputs
│   ├── test-1-[entity].md
│   └── test-2-[entity].md
├── scores.md                   # Rubric + blind scores, before/after if autoresearch
└── SUBMISSION-SUMMARY.md       # Generated from template below
```

### 4b. Generate SUBMISSION-SUMMARY.md

Read [references/submission-template.md](references/submission-template.md) and fill in every field. The template covers: author, what it does, scores, test results, data sources, discoveries, and questions.

### 4c. Include skills graph context

Append the "About the Revenue Skills Graph" section from [references/skills-graph-context.md](references/skills-graph-context.md) to the SUBMISSION-SUMMARY.md. Add: "**Improvement potential:** Based on the current score of [X]/100, the team estimates this skill could reach [estimated ceiling] with autoresearch optimization."

### 4d. Share instructions

Tell the user:

> "Your skill is packaged and ready! Share it with **any** of the Revenue Skills Graph team:
>
> **The team:** Venkat Subramaniam, Hilary Horner, Taylor, Kiri, Christen, or Elyse. Message whoever you're most comfortable with.
>
> **Recommended: Slack** — Send the `SUBMISSION-SUMMARY.md` + the full `[skill-name]-submission/` folder to any team member on Slack, or post in the revenue skills channel.
>
> **Alternative: GitHub** (only if you have the shared brain repo cloned at `~/Documents/revenue-skills-brain`):
> ```bash
> cd ~/Documents/revenue-skills-brain
> git checkout -b submission/[your-name]/[skill-name]
> cp -r [skill-name]-submission/ skills/submissions/[skill-name]/
> git add . && git commit -m 'submission: [skill-name] by [author]'
> git push -u origin submission/[your-name]/[skill-name]
> ```
>
> **Option 3 (Email):** Zip the folder and send to any team member.
>
> The team reviews submissions weekly. You'll hear back with either an approval, improvement suggestions, or questions."

### 4e. Install locally

Also install the skill for the user's own agent:

```bash
mkdir -p ~/.pi/agent/skills/[skill-name]
cp SKILL.md ~/.pi/agent/skills/[skill-name]/SKILL.md
```

> "Your skill is also installed locally — you can start using it right now. Just say '[trigger phrase]' and your AI agent will run it."

### 4f. Closing message

Tell the user:
**✅ Phase 4 Final Checklist** (verify ALL before closing):
- [ ] SKILL.md finalized and saved
- [ ] BUILD-LOG.md generated with test results, scores, discoveries
- [ ] SUBMISSION-SUMMARY.md generated from template
- [ ] Skills graph context appended to summary
- [ ] Submission package directory created with all files
- [ ] Skill installed locally at `~/.pi/agent/skills/[name]/SKILL.md`
- [ ] User knows how to share (Slack recommended)
- [ ] User knows the trigger phrase to use the skill immediately

> "✅ **You're done!** Here's a recap:
> - Your skill **[name]** is built, tested, and scored at **[X]/100** ([tier])
> - It's installed locally — you can use it right now by saying '[trigger phrase]'
> - The submission package is ready to share with the team
>
> **Why sharing matters:** The Revenue Skills Library currently has 53 skills used by reps and RevOps across the org. When you share yours:
> - 📊 **Your workflow gets hardened** — the team runs it through blind testing against real BQ data and can push it to 78+ (Excellent tier) using autoresearch
> - 🚀 **Every rep benefits** — your tribal knowledge becomes a tool anyone can use. A new hire on your team could run your skill on day 1 instead of learning it over 6 months.
> - 🏆 **You get credit** — your name stays on the skill as author. Your domain expertise is permanently captured.
> - 🔗 **It connects to everything else** — skills link to each other. Your hot-leads skill might feed into someone else's meeting-prep skill, creating compound value neither could do alone.
>
> The best skills in the library started exactly like yours — one rep describing what they actually do, then the quality system turning it into something reliable. The org gets smarter every time someone shares.
>
> Message any team member (Venkat, Hilary, Taylor, Kiri, Christen, Elyse) or post in the revenue skills channel. They review weekly."

---

## Reference Files

Load these on demand — do not read upfront:

| File | When to read |
|------|-------------|
| [references/skills-graph-context.md](references/skills-graph-context.md) | When user asks "what is the skills graph?" or needs more context |
| [references/autoresearch-walkthrough.md](references/autoresearch-walkthrough.md) | Only in Phase 3B when user chooses autoresearch |
| [references/quality-checklist.md](references/quality-checklist.md) | When scoring in Phase 2 |
| [references/table-quick-reference.md](references/table-quick-reference.md) | When mapping user's data sources to BQ tables in Phase 1 |
| [references/submission-template.md](references/submission-template.md) | When packaging in Phase 4 |
