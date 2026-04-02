# Response Templates — Customization Guide

## Tone Rules

All responses to submitters follow these rules:
1. **Lead with gratitude** — they took 45-90 minutes to build something for the team
2. **Be specific** — "your decision tree in Step 3" not "your workflow is good"
3. **Be honest** — if the skill needs work, say so. Vague praise followed by rejection is worse than direct feedback.
4. **Give them something actionable** — every "needs improvement" item includes the exact fix, not just what's wrong
5. **Keep it short** — submitters are busy reps. 10 lines max for the core message.

## Template Variables

Replace these in every template:
- `[Name]` — submitter's first name
- `[skill-name]` — the submitted skill's name
- `[X]` — actual score
- `[tier]` — Stub/Functional/Good/Excellent
- `[existing-skill-name]` — for WEAVE, the skill being woven into
- `[N]` — number of users/installs of the target skill

## Customization by Submitter Role

| Role | Adjust tone |
|------|------------|
| AE | Focus on "your workflow is now a tool anyone can use" — they care about scale and recognition |
| SE | Focus on technical quality — they appreciate the scoring rigor |
| CSM | Focus on "this helps every CSM onboard faster" — they care about team knowledge sharing |
| RevOps | Focus on "this standardizes a process" — they care about consistency |
| SDR | Focus on "saves you 30 min per day" — they care about time |

## When the Submitter is a Known Contributor

If the submitter is Kiri, Elyse, Taylor, Christen, or another active contributor:
- Skip the explanatory context (they know how the library works)
- Be more direct with technical feedback
- Reference their previous contributions: "This pairs well with your [previous-skill]"

## When the Submitter is Brand New

If this is their first submission:
- Include the "About the Revenue Skills Graph" context
- Explain the scoring system briefly
- Be extra encouraging — getting someone to submit twice is harder than getting them to submit once
- Offer to pair on improvements: "Want to hop on a quick call?"

## Escalation Templates

### When You Can't Decide (ACCEPT vs WEAVE)

Message to the reviewer:
```
I'm 50/50 on this one. [skill-name] by [Name] scores [X]/100.

The overlap with [existing-skill] is partial:
- Overlaps: [what]
- New: [what]

My lean is [ACCEPT/WEAVE] because [reason], but [counterargument].

Want to discuss before I draft the response?
```

### When the Submission Reveals a Library Gap

Message to the reviewer:
```
[Name]'s submission for `[skill-name]` revealed a gap: [description].

None of our existing 53 skills cover [specific workflow].
This submission is a [score] but the CONCEPT is valuable.

Recommend: [ACCEPT and iterate / Build a proper version inspired by this / Add to skills backlog]
```

### When the SQL Has Real Bugs

Message to the reviewer:
```
⚠️ SQL issue in `[skill-name]` submission:

[Specific query] uses [wrong pattern].
This would return [wrong result] because [explanation].

Fix: [corrected SQL]

This is a teaching moment — include the fix in the response so the submitter learns the gotcha.
```
