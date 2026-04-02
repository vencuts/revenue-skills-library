# WEAVE Decision Tree — Detailed Guide

## The Core Question

When a submission arrives, the fundamental question is: **does this workflow already exist in the library, partially or fully?**

## Decision Flow

```
SUBMISSION ARRIVES
│
├─ Step 1: Trigger phrase overlap check
│  Search existing skills for matching triggers.
│  "hot leads" → does deal-prioritization already cover this?
│  "call prep" → does meeting-prep already cover this?
│  If 0 overlapping triggers → likely NEW
│  If 2+ overlapping triggers → likely WEAVE candidate
│
├─ Step 2: Data source overlap check
│  Does the submission query the same BQ tables as an existing skill?
│  Same tables + same joins = strong overlap signal
│  Same tables + different joins/filters = partial overlap (may still be new)
│  Different tables entirely = likely NEW
│
├─ Step 3: Output overlap check
│  Does the submission produce the same kind of output?
│  Both produce "deal health scorecard" → WEAVE
│  One produces "pipeline report", other produces "call coaching" → different enough for NEW
│
└─ Step 4: Decision logic overlap check (most important)
   Does the submission add NEW decision logic that doesn't exist anywhere?
   New decision tree with domain-specific thresholds → valuable regardless of overlap
   Same checks but different data → WEAVE the data, not a new skill
   Genuinely novel workflow → ACCEPT as new
```

## WEAVE Rules (from METHODOLOGY.md)

1. **WEAVE into steps, not APPEND sections.** The new logic goes INTO the existing workflow where it's needed, not tacked on at the end.
2. **Replace, don't layer.** If the submission has a better version of a step, replace the old one. Don't create Step 3a (old) and Step 3b (new).
3. **One WEAVE per concept.** Don't try to weave 5 things from one submission. Pick the 1-2 highest-value pieces.
4. **Grade before and after.** Score the existing skill before WEAVE, score after. If score didn't improve, revert.
5. **Update the registry.** Add a WEAVE decision record to the submission log.

## WEAVE Decision Records — Format

```markdown
| Date | Skill | Submission | Decision | Rationale |
|------|-------|-----------|----------|-----------|
| 2026-04-02 | deal-prioritization | capital-hot-leads by Dillon | WEAVE | Capital urgency signals woven into Step 2 priority scoring |
```

## Common WEAVE Patterns

| Submission type | Likely target | What to weave |
|-----------------|---------------|---------------|
| "My version of loss analysis" | loss-intelligence | Domain-specific loss signals they discovered |
| "How I prep for calls" | meeting-prep | Additional data checks or decision criteria |
| "Pipeline scoring" | deal-prioritization | New scoring dimensions or thresholds |
| "Outreach emails" | outbound-cadence | Industry-specific templates or timing data |
| "Account research for [vertical]" | account-research | Vertical-specific data sources or checks |

## When NOT to WEAVE (Accept as New Instead)

- Submission covers a **different persona** (CSM skill vs AE skill for the same data)
- Submission has a **fundamentally different workflow** (even if same data sources)
- Submission serves a **different moment** (pre-call vs post-call, even if same account data)
- Existing skill is already 400+ lines — adding more would bloat it past usability
