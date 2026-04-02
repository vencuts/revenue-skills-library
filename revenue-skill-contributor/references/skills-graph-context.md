# The Revenue Skills Graph — What It Is and Why It Matters

## The Problem

Revenue teams (AEs, SEs, CSMs, RevOps) waste hours on repetitive analytical workflows:
- Investigating why deals were lost
- Preparing for merchant calls
- Analyzing pipeline health
- Writing follow-up emails with the right data
- Checking deal compliance against Rules of Engagement

These workflows require pulling data from 5+ systems (Salesforce, BigQuery, Slack, SE-NTRAL, Google Drive), applying domain-specific rules (PBR not LTR, SAFE_DIVIDE, correct segment attribution), and producing structured output. Most reps do this manually and inconsistently.

## The Solution

The Revenue Skills Graph is a curated library of AI agent skills that automate these workflows. Each skill is a structured set of instructions that teaches an AI agent how to perform a specific revenue task — pulling the right data from the right tables, applying the right business rules, and producing actionable output.

**Current state (April 2026):**
- **53 skills** covering pipeline analysis, loss investigation, meeting prep, call coaching, deal prioritization, competitive positioning, and more
- **25 reference files** with validated BQ table schemas, join patterns, metric definitions
- **4-layer architecture**: Integrity → Data → Analysis → Action
- **Rigorous quality system**: 7-dimension rubric scoring, blind evaluation against real BigQuery data, autoresearch optimization

## The Team

Maintained by a cross-functional group in Hilary Horner's Rev Ops org:
- **Venkat Subramaniam** — architect, built the quality system and methodology
- **Hilary Horner** — executive sponsor, Rev Ops leader
- **Taylor, Kiri, Christen, Elyse** — skill contributors, testers, domain experts

Collaborating with Spencer Lawrence's Data Science team (who own the underlying BQ tables and River integration).

## Why Your Contribution Matters

Every skill in the library started as tribal knowledge in someone's head. The difference between a rep who closes at 30% and one who closes at 45% is often a workflow — a specific sequence of checks, data pulls, and decisions that the top performer does automatically.

When you contribute a skill, you're:
1. **Capturing your expertise** so it doesn't walk out the door when you change roles
2. **Scaling your best practices** to every rep who installs the skill
3. **Improving the library's coverage** — gaps in the graph are gaps in the org's capability
4. **Getting your workflow scored and hardened** by a quality system that's caught 5 bugs in 4,998 lines of reference material

## Quality Standard

Skills are scored on a 100-point scale across 7 dimensions:
- Problem Definition & Scope (15)
- Tool & Data Source Spec (10)
- Investigation Workflow (20)
- SQL & Data Queries (15)
- Output Format & Template (15)
- Error Handling & Edge Cases (10)
- Anti-Gaming Quality Signals (15)

**Tier system:**
| Score | Tier | Meaning |
|-------|------|---------|
| <50 | Stub | Placeholder — needs significant work |
| 50-69 | Functional | Works for happy path, breaks on edge cases |
| 70-77 | Good | Reliable, handles errors, domain-aware |
| 78+ | Excellent | Production-grade, comprehensive, tested |

The submission threshold is **70+**. Most skills arrive at 55-65 and get improved through the review process.

## What Happens After You Submit

1. **Review** — The team reads your skill, runs it against test cases, scores it
2. **Decision** — Three outcomes:
   - **Add as new skill** — fills a gap in the graph
   - **Weave into existing** — your insights improve an existing skill (no duplication)
   - **Iterate** — team sends improvement suggestions, you refine together
3. **Publish** — Merged into the shared repository, available to everyone who has the skills installed
4. **Credit** — Your name stays on the skill as author. Your domain expertise is permanently captured.

## The Autoresearch Option

For skills that need to go from 65 → 78+, we use an autonomous optimization loop called autoresearch:
- The AI tries small improvements to the skill
- Each change is scored against blind test cases
- Improvements are kept, failures are reverted
- This runs for 10-50 iterations, often pushing scores up 10-15 points

This is optional and requires some technical comfort. The team can run it for you if you prefer.
