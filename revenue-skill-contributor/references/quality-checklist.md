# Quality Checklist — Revenue Skill Scoring

## 7-Dimension Rubric

### 1. Problem Definition & Scope (15 pts)

| Score | Criteria |
|-------|----------|
| 13-15 | Clear problem, specific trigger phrases, explicit scope boundaries, states what skill does NOT do |
| 9-12 | Clear problem but vague triggers or missing boundaries |
| 5-8 | Generic problem statement, no triggers |
| 0-4 | No clear problem definition |

**What top skills do:** Name specific user phrases that trigger the skill. State 2-3 things the skill explicitly does NOT cover and point to which skill handles those instead.

### 2. Tool & Data Source Spec (10 pts)

| Score | Criteria |
|-------|----------|
| 9-10 | Tools listed as TABLE (name, purpose, when), fully-qualified BQ table names, fallback sources |
| 6-8 | Tools listed but not as table, some qualified names |
| 3-5 | Mentions tools vaguely |
| 0-2 | No tool specification |

**What top skills do:** List every tool in a markdown table with columns: Tool | Purpose | When to Use. Every BQ table uses `project.dataset.table` format. Fallback data sources specified for when primary fails.

### 3. Investigation Workflow (20 pts)

| Score | Criteria |
|-------|----------|
| 17-20 | Decision trees with conditional paths, numbered steps, parallel operations where applicable |
| 12-16 | Linear steps with some conditionals |
| 7-11 | Linear steps, no branching |
| 0-6 | Vague instructions |

**What top skills do:** "If [condition], do [X]. Otherwise, do [Y]." Real workflows branch. A skill that's just Step 1 → Step 2 → Step 3 with no conditions doesn't reflect reality.

### 4. SQL & Data Queries (15 pts)

| Score | Criteria |
|-------|----------|
| 13-15 | Real BQ queries, tested, SAFE_DIVIDE, PBR (not LTR), date alignment, join hints |
| 9-12 | Real queries but untested or missing gotcha handling |
| 5-8 | Pseudocode or partial queries |
| 0-4 | No SQL |

**Critical rules:**
- Use `PBR` (Projected Billed Revenue), NEVER `LTR` (Lifetime Revenue) — deprecated
- Use `SAFE_DIVIDE(numerator, denominator)` — avoids division by zero
- Use `sales_user_roles.segment` for segment — NOT `market_segment` (has stale values like "Cross-Sell")
- Use `CURRENT_DATE()-1` for YoY comparisons — avoids incomplete today data
- Fully-qualified names: `shopify-dw.rpt_salesforce_banff.opportunity`

### 5. Output Format & Template (15 pts)

| Score | Criteria |
|-------|----------|
| 13-15 | Conditional output (different format based on findings), verdict-first, concrete template |
| 9-12 | Fixed template with good structure |
| 5-8 | Generic "summarize findings" |
| 0-4 | No output specification |

**What top skills do:** "If [situation A], format output as [X]. If [situation B], format as [Y]." The output changes based on what the data shows, not a one-size-fits-all template. Always lead with a verdict sentence before the evidence.

### 6. Error Handling & Edge Cases (10 pts)

| Score | Criteria |
|-------|----------|
| 9-10 | 8+ error scenarios WOVEN INTO steps (not in a separate section), graceful degradation |
| 6-8 | Some error handling woven in |
| 3-5 | Error handling in separate section at bottom (appended, not woven) |
| 0-2 | No error handling |

**The WEAVE pattern:** Error handling goes INSIDE each workflow step, not in a section at the bottom. Example:

```
### Step 3: Pull call transcripts
Query sales_calls for the opportunity...

**If no calls found:** State "No recorded calls found for this opportunity.
Analysis based on pipeline data only." Do NOT fabricate call insights.

**If calls found but no transcripts:** Note "X calls recorded but transcripts
unavailable" and continue with metadata (date, duration, attendees).
```

### 7. Anti-Gaming Quality Signals (15 pts)

| Score | Criteria |
|-------|----------|
| 13-15 | Domain vocabulary, specific not vague, negative boundaries, SQL interpretation guidance |
| 9-12 | Some domain specifics |
| 5-8 | Generic instructions that could apply to any domain |
| 0-4 | Boilerplate |

**What this catches:** Skills that LOOK good (right section headers, formatted nicely) but are actually generic. A skill that says "analyze the data and provide recommendations" scores 3/15 here. A skill that says "if conversion_rate > 50%, flag as suspect — this usually indicates a tracking issue, not actual conversion" scores 13/15.

---

## The 72→78 Upgrade Checklist

Skills that plateau at 72 usually need these specific improvements to reach 78+:

- [ ] Tools listed as a TABLE (not prose)
- [ ] 8+ error scenarios woven into steps (not appended)
- [ ] Conditional output format (varies by findings)
- [ ] Decision trees in workflow (not just linear steps)
- [ ] SQL with interpretation guidance ("If X > Y, this means...")
- [ ] Domain vocabulary throughout (not generic analytics terms)
- [ ] Negative instructions ("Do NOT hallucinate call content")
- [ ] Explicit scope boundaries ("This skill does NOT handle...")
- [ ] Fallback data sources for each primary source
- [ ] Verdict-first output format

---

## Common Mistakes

| Mistake | Why it's bad | Fix |
|---------|-------------|-----|
| Using `LTR` | Deprecated metric. Team uses PBR. | Replace with `PBR` everywhere |
| Using `market_segment` | Stale values like "Cross-Sell" | Use `sales_user_roles.segment` |
| Raw division | Divide by zero crashes | Use `SAFE_DIVIDE()` |
| Error handling at bottom | Gets ignored by the agent | WEAVE into each step |
| "Analyze the data" | Too vague, agent improvises | Specify exact checks and thresholds |
| No negative boundaries | Skill scope creeps | Add "This skill does NOT..." section |
| Single output format | Doesn't adapt to findings | Add conditional formatting |
| Local file/path dependencies (e.g., `~/Documents/`, `my-data.csv`) | Skill only works on author's machine | Replace with MCP tools, BQ queries, or Slack search — universal sources only |
| Personal env/config assumptions (API keys, local scripts, env vars) | Other users don't have your setup | Use tool discovery (e.g., `data-portal-mcp`) instead of hardcoded paths |
