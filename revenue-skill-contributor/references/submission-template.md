# Submission Template

Use this template to generate SUBMISSION-SUMMARY.md in Phase 4.

Fill in every field. If a field doesn't apply, write "N/A" — don't leave it blank.

---

```markdown
# Skill Submission: [skill-name]

## Author
- **Name:** [Full name]
- **Role:** [AE / SE / CSM / RevOps / SDR / Other]
- **Team:** [Team or pod name]
- **Date:** [Submission date]

## What This Skill Does
[2-3 sentences in plain language. Describe the workflow, not the technology.
Example: "Analyzes why a deal was lost by pulling call transcripts, email history,
stage progression, and SE engagement data, then synthesizes a root cause analysis
with coaching recommendations."]

## Trigger Phrases
[What would a user say to invoke this skill?]
- "[Example phrase 1]"
- "[Example phrase 2]"
- "[Example phrase 3]"

## Quality Scores
| Metric | Score |
|--------|-------|
| Rubric (structural) | /100 |
| Blind (functional) | /100 (if run) |
| Combined | /100 |
| Autoresearch | Yes/No — iterations: , score change: → |

## Tested On
| Entity | Type | Result | Notes |
|--------|------|--------|-------|
| [Name/ID] | Happy path | Pass/Fail | |
| [Name/ID] | Sparse data | Pass/Fail | |
| [Name/ID] | Edge case | Pass/Fail | |

## Data Sources Used
| Table | Purpose |
|-------|---------|
| `project.dataset.table` | [What this table provides] |
| ... | ... |

## MCP/Tool Dependencies
[List any MCP servers, CLI tools, or Quick site APIs the skill uses]
- [ ] BigQuery (data-portal-mcp)
- [ ] Slack (slack-mcp)
- [ ] SE-NTRAL (Quick API)
- [ ] Other: [specify]

## What I Learned Building This
[Discoveries, gotchas, patterns that could help others build skills]
- [Discovery 1]
- [Discovery 2]

## Questions for the Team
[Anything uncertain, governance questions, areas where guidance is needed]
- [Question 1]
- [Question 2]

---

## About the Revenue Skills Graph

The Revenue Skills Graph is a curated library of 53+ AI agent skills that automate
revenue workflows — from pipeline analysis to loss investigation to meeting prep.
Maintained by the Rev Ops team (Venkat Subramaniam, Hilary Horner, Taylor, Kiri,
Christen, Elyse), it uses a rigorous quality system: 7-dimension rubric scoring,
blind evaluation against real BigQuery data, and autoresearch optimization loops.

Your submission will be reviewed against this quality bar. The team decides whether to:
- **Add as a new skill** — fills a gap in the graph
- **Weave into an existing skill** — your insights improve what already exists
- **Iterate together** — team sends improvement suggestions

Either way, your domain expertise makes the library stronger. The goal: capture tribal
knowledge that currently lives in people's heads and make it available to every rep
and RevOps person across the org.

**Contact:** Venkat Subramaniam (Slack) or post in the revenue skills channel.
```
