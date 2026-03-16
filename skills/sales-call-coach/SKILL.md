---
name: sales-call-coach
description: Evaluate and coach on sales calls using Salesloft transcripts from BigQuery. Supports discovery, demo, and solutioning call types with competency scoring (1-5), Challenger discovery framework, Demo2Win methodology, and actionable coaching. Use when asked to "coach me", "evaluate this call", "how should I approach", "review my demo", "discovery coaching", "call feedback", "score my call", or "what could I improve". Works for AEs, SEs, and sales managers who want to develop their craft.
---

# Sales Call Coach

Evaluate sales calls and provide structured coaching using Salesloft transcripts fetched from BigQuery. **Coaching only when requested — never unsolicited.**

---

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Fetch Salesloft transcripts, MEDDPICC data, call metadata from `base__salesloft_conversations_extensive` | Ask user to paste transcript text or Salesloft URL. Note: "Auto-fetch unavailable — coaching from pasted text only." |
| `vault_search` | Look up user profile (name, role, Enneagram type) for personalized coaching tone | Skip personality-based coaching adaptation. Use generic coaching tone. |
| `perplexity_search` | Look up Challenger methodology resources, Demo2Win techniques | Use inline framework knowledge from this skill. |

**Key table**: `shopify-dw.base.base__salesloft_conversations_extensive` contains:
- `summary.text` — AI call summary (200-500 words)
- `transcript_text` — full verbatim transcript (preferred over summary for coaching)
- `attendees` — REPEATED RECORD with `full_name`, `email`, `is_internal`, `percent_talk_time`
- `meddpicc` — structured MEDDPICC methodology data extracted from the call
- `key_moments` — categorized key moments (objection, commitment, question, etc.)
- `duration_seconds` — call length (< 300s = short call, < 120s = likely a quick check-in, not coachable)

---

## Frameworks

### Challenger (Discovery Calls)
Challenge the merchant's thinking, reframe perspectives, lead to new opportunities. Key behaviors:
- **Teach** — Share insights the merchant hasn't considered
- **Tailor** — Connect insights to their specific business context
- **Take Control** — Guide the conversation toward a decision path

### Demo2Win (Demo Calls)
Tell → Show → Tell. Every element maps to a documented merchant need:
1. **Tell** what capability you're about to show and why it matters to THEM
2. **Show** the feature/workflow in action
3. **Tell** why it matters — connect back to their business outcome

### MEDDPICC (Qualification / Solutioning)
Metrics, Economic Buyer, Decision Criteria, Decision Process, Paper Process, Implications of Pain, Champion, Competition.

---

## Workflow

### Step 1: Gather Context

**Automatic (parallel):**
1. **User profile** — If `agent-vault` available, fetch name, role, Enneagram type via `get_user("@me")`
2. **Transcript** — Determine source:
   - **User provides Salesloft conversation URL/ID** → extract conversation_id, query BQ directly
   - **User provides meeting date + merchant name** → search BQ by date + attendee
   - **User pastes transcript text** → use directly (skip BQ)

**BigQuery transcript query:**
```sql
SELECT c.conversation_id, c.title, c.duration, c.event_start_date,
       c.summary.text as summary,
       c.key_moments,
       c.meddpicc,
       ARRAY_AGG(STRUCT(a.full_name, a.email, a.is_internal, a.percent_talk_time)) as attendees
FROM `shopify-dw.base.base__salesloft_conversations_extensive` c,
     UNNEST(c.attendees) a
WHERE c.conversation_id = '[CONVERSATION_ID]'
GROUP BY 1,2,3,4,5,6,7
```

If searching by date + merchant:
```sql
SELECT c.conversation_id, c.title, c.duration, c.event_start_date,
       c.summary.text as summary
FROM `shopify-dw.base.base__salesloft_conversations_extensive` c,
     UNNEST(c.attendees) a
WHERE a.is_internal = FALSE
  AND LOWER(a.email) LIKE '%[merchant_domain]%'
  AND DATE(c.event_start_date) = '[YYYY-MM-DD]'
GROUP BY 1,2,3,4,5
ORDER BY c.event_start_date DESC
LIMIT 5
```

### Step 2: Classify Call Type

Auto-detect from title/content. Ask user to confirm if ambiguous.

| Call Type | Signals |
|---|---|
| **Discovery** | "discovery", "intro", "initial", heavy questioning, pain exploration |
| **Demo** | "demo", "demonstration", "walkthrough", "show", feature presentation |
| **Solutioning** | "solution", "architecture", "technical", "requirements", integration design |
| **Negotiation** | "pricing", "contract", "proposal", "terms" |

### Step 3: Analyze

**Competencies by call type:**

| Discovery | Demo | Solutioning |
|---|---|---|
| Technical Discovery (1-5) | Solution Alignment (1-5) | Solution Alignment (1-5) |
| Questioning Technique (1-5) | Value Positioning (1-5) | Ecosystem Knowledge (1-5) |
| Effective Communication (1-5) | Effective Communication (1-5) | Questioning Technique (1-5) |

**Scoring scale:**
- **5 — Exceptional:** Mastery level, teachable moments for others
- **4 — Strong:** Consistently effective, minor refinement opportunities
- **3 — Solid:** Competent performance, clear improvement path
- **2 — Developing:** Foundational skills present, significant growth needed
- **1 — Needs Focus:** Priority development area

**Analysis dimensions:**
- **Talk ratio** — Was it balanced? Did the seller listen enough? (Ideal: merchant talks 60%+)
- **Question quality** — Open-ended? Follow-up depth? Did they uncover the real pain?
- **Value positioning** — Features connected to business outcomes? Or just feature demos?
- **Challenger behavior** — Did they teach, tailor, take control? Or just respond?
- **Next steps** — Clear, committed, with dates? Or vague "we'll follow up"?
- **MEDDPICC coverage** — Which elements were addressed? What's missing?

### Step 4: Generate Evaluation

**In-chat scorecard:**

```markdown
## 📊 Call Evaluation: [Seller Name]

**Call Type:** [Discovery/Demo/Solutioning]
**Merchant:** [Merchant Name]
**Date:** [Call Date] | **Duration:** [X min]
**Overall Score:** [X.X/5.0] ⭐

### Scorecard

| Competency | Score | Notes |
|---|---|---|
| [Competency 1] | [X/5] ⭐⭐⭐⭐ | [Specific observation] |
| [Competency 2] | [X/5] ⭐⭐⭐ | [Specific observation] |
| [Competency 3] | [X/5] ⭐⭐⭐⭐⭐ | [Specific observation] |

**Average:** [X.X/5]

### 💪 Strengths
- [Strength with specific example from the call]
- [Strength]

### 🎯 Top 3 Improvements

1. **[Competency Area]**
   - **What happened:** [Specific moment from the call]
   - **What to do instead:** [Concrete alternative behavior]
   - **Next call action:** [One thing to try on the next call]

2. **[Competency Area]**
   - **What happened:** [Moment]
   - **What to do instead:** [Alternative]
   - **Next call action:** [Action]

3. **[Competency Area]**
   - **What happened:** [Moment]
   - **What to do instead:** [Alternative]
   - **Next call action:** [Action]

### 📈 Talk Ratio
Seller: [X%] | Merchant: [Y%]
[Assessment — too much seller talk? Well balanced?]

### 🔍 MEDDPICC Coverage
| Element | Covered | Notes |
|---|---|---|
| Metrics | ✅/❌ | [Brief] |
| Economic Buyer | ✅/❌ | [Brief] |
| Decision Criteria | ✅/❌ | [Brief] |
| Decision Process | ✅/❌ | [Brief] |
| Paper Process | ✅/❌ | [Brief] |
| Implications of Pain | ✅/❌ | [Brief] |
| Champion | ✅/❌ | [Brief] |
| Competition | ✅/❌ | [Brief] |
```

---

## Enneagram-Tailored Coaching

If user's Enneagram type is known (from Vault profile), tailor coaching tone:

| Type | Coaching Focus |
|---|---|
| **1 (Perfectionist)** | Progress over perfection. Celebrate incremental wins. |
| **2 (Helper)** | Set boundaries. Your growth matters too. |
| **3 (Achiever)** | Authenticity over performance. Depth over speed. |
| **4 (Individualist)** | Channel creativity into solutions. |
| **5 (Investigator)** | Share knowledge generously. Engage more actively. |
| **6 (Loyalist)** | Trust your expertise. Decide with confidence. |
| **7 (Enthusiast)** | Structure and follow-through. Finish before starting new. |
| **8 (Challenger)** | Balance directness with empathy. |
| **9 (Peacemaker)** | Assert authority. Your voice matters. |

---

## Demo Call Visual Assessment (Additional)

For demo calls, add a visual/presentation checklist:

| Dimension | Score (1-5) | Notes |
|---|---|---|
| Personalization & Relevance | [X] | Custom data, merchant-specific scenarios? |
| Compelling Moments | [X] | "Wow" moments, business value reveals? |
| Engagement & Flow | [X] | Smooth navigation, presenter energy? |

**Reflection prompts:**
1. "What would you do differently in your next demo?"
2. "What went really well?"

---

## Coaching Domain Rules — Hard-Won Knowledge

- **Never score an AE on something they didn't attempt.** If they didn't ask about budget, that's a miss — but only if budget was appropriate to discuss at that call stage. Discovery call = budget is fair game. First intro call = budget question is premature. Context matters.
- **"Challenger" doesn't mean "combative."** Teaching the merchant something new ≠ arguing with them. If transcript shows AE pushing back aggressively, that's NOT Challenger — that's poor rapport. Challenger is: "Here's a trend in your industry that might change how you think about X."
- **Talk time is the most objective metric.** AE > 70% = talking too much, AE < 30% = not engaging enough. 40-60% is the sweet spot. Always calculate this first — it overrides other impressions. An AE who "seemed confident" but talked 80% was performing, not selling.
- **MEDDPICC scoring should be generous on early calls.** A first discovery call that uncovers Metrics + Pain = excellent. Expecting Paper Process + Competition on call 1 is unrealistic. Score based on call stage, not absolute completeness.
- **"Did the merchant talk about problems or features?"** If the merchant is describing problems, the AE is doing good discovery. If the merchant is asking about features, the AE hasn't uncovered pain yet — they're being treated as a vendor, not an advisor.
- **Demo coaching: "show, don't tell" is not enough.** The best demos connect each feature shown to a SPECIFIC pain the merchant mentioned in discovery. If the demo doesn't reference the discovery call, it's a generic demo regardless of presentation quality.
- **Never coach on the outcome.** A call that ended in "no" was not necessarily bad. A call that ended in "yes" was not necessarily good. Coach on the PROCESS — did they ask the right questions, listen, adapt, and guide?

## Error Handling

| Scenario | Action |
|----------|--------|
| No transcript found for company/date | Try: (1) broader date range, (2) alternate company name, (3) search by AE name instead. If still nothing: "No recorded call found. Paste the transcript or provide the Salesloft URL." |
| Multiple transcripts match | List all with date, duration, attendees. Ask: "Which call? I found {N} matches." Do NOT auto-pick. |
| Vault unavailable | Skip Enneagram-based coaching. Use generic tone. Note: "Personalized coaching style unavailable." |
| Short call (< 5 min / < 300 seconds) | Note: "This was a {N}-minute call — limited coaching data. Focus: did they accomplish the call objective?" |
| `transcript_text` is NULL but `summary.text` exists | Use summary for coaching. Flag: "Coaching from AI summary only — full transcript unavailable. Specific quote analysis not possible." |
| Call type ambiguous (user says "coach this call" but doesn't specify discovery/demo/solutioning) | Infer from transcript content: questions → discovery, screen share mentions → demo, solution discussion → solutioning. If still unclear: ask. |
| MEDDPICC data incomplete (some fields NULL) | Coach on available fields. Note: "MEDDPICC data partial — {X} and {Y} not captured in this call. Consider whether those elements were addressed off-transcript." |
| Talk time shows AE spoke > 70% | Flag immediately as coaching priority: "AE spoke {X}% — significantly above the 40-60% ideal range. Key area: let the merchant talk more." |
| Transcript from an internal call (no external attendees) | Flag: "This appears to be an internal call, not a merchant interaction. Sales coaching applies to external calls. Want me to evaluate anyway?" |
| User asks to coach a call they didn't attend | Provide analysis but note: "You weren't on this call — coaching is observational, not experiential. Recommend discussing findings with the AE who ran it." |

---

## Detailed Evaluation Framework

See `references/evaluation-framework.md` for full competency rubrics, Demo2Win visual assessment details, and HTML artifact structure.
