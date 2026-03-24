# Autoresearch: csm-portfolio-triage

## Objective
Optimize `SKILL.md` to maximize composite score across 4 real-data test scenarios pulled from CS Compass (8,159 live accounts).

## Metrics
- **Primary**: `quality_score` (composite average of 4 scenarios, 0-100, higher is better)
- **Secondary**: `scenario_1_base`, `scenario_2_csm_portfolio`, `scenario_3_risk_overrides`, `scenario_4_rhs_distribution`

## How to Run
`bash autoresearch.sh` — pulls live data from CS Compass Quick.db, runs 4 LLM-judge scenarios, outputs METRIC lines. ~60s per run.

## Files in Scope
- `SKILL.md` — the skill being optimized. All content is fair game.

## Off Limits
- `eval/` — test harness, test data builders, grader prompts (frozen)
- `autoresearch.sh` — the eval script (frozen)
- `autoresearch.md` — this file (update What's Been Tried section only)

## Constraints
- SKILL.md must stay ≤ 500 lines
- Must keep production-validated SQL queries
- Must maintain CS domain accuracy (real segment names, risk flags, table names)
- Must be installable to `~/.pi/agent/skills/` and `~/.claude/skills/`

## Test Scenarios
1. **Base real-data** (8,159 accounts): Data handling, classification, actionability, edge cases, domain accuracy
2. **Single CSM portfolio** (Melanie LeBlanc, 6 CRITICAL accounts, Large Accounts): Full triage flow with real risk flags, GMV $70M-$206M, mitigation statuses (draft, pending_lead)
3. **Risk overrides** (NZXT with lead-approved override to MODERATE): Override lifecycle handling, suppress false Act Now flags
4. **RHS distribution stress** (49% At Risk, 42% Atrophying, 9% Healthy): Alert fatigue prevention, portfolio-size normalization

## What's Been Tried
- **Baseline**: 62/100 composite. Gaps: no risk flag taxonomy, no mitigation awareness, weak edge cases.
- **Exp 2 (risk flags + mitigations)**: 72/100. Added 21-flag taxonomy, mitigation status checks, risk_score 0-29 scale. S1:72 S2:? S3:? S4:?
- **Exp 3 (RHS tier + conflict resolution)**: 78/100 on S1. Added RHS tier interpretation, risk_category vs RHS conflict rule. S1:78 S2:92 S3:45 S4:72 → Composite 72.
- **Exp 4 (risk overrides + atrophying + normalization)**: Added override logic (active/expired/reactivated), Gate 6b for Atrophying, portfolio-size normalization caps. NOT YET SCORED.
- **Key insight**: Scenario 3 (risk overrides) is the weakest — scored 45 because skill had zero override handling. Now added explicit override query, lookup map, and gate logic.
- **Key insight**: Scenario 4 needs alert fatigue prevention — 49% of accounts are At Risk but a useful triage has 3-5 Act Now max.
