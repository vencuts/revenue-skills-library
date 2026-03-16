# Revenue Skill Quality Rubric
# Used by LLM judge to score skills against gold-standard patterns
# Extracted from: payments-platform-atc (158 lines), customer-account-triage (235 lines),
# meeting-prep (219 lines), account-context-sync (217 lines)

## Scoring (0-100)

### 1. Problem Definition & Scope (0-15)
- **15**: Clear problem statement. Explicit scope boundaries (what it does AND doesn't do). Distinct modes if applicable (e.g., "Batch Triage" vs "Single Thread" vs "Shift Handoff").
- **10**: Problem stated but scope boundaries vague. No distinction between modes/use cases.
- **5**: One-liner purpose only. No scope boundaries.
- **0**: No clear problem definition.

**Gold pattern (customer-account-triage):** "You triage questions in #help-customer-account-and-login... You are NOT the ATC. You produce drafts — never post directly." — Clear scope with explicit negative boundary.

### 2. Tool & Data Source Specification (0-10)
- **10**: Lists specific tools with their PURPOSE (not just names). Has a table mapping tool → what it's used for. Handles tool unavailability gracefully ("if X is unavailable, tell the user what you would have checked").
- **7**: Lists tools but doesn't explain when to use each one.
- **3**: Mentions "BigQuery" or "Observe" generically without specifics.
- **0**: No tool specification.

**Gold pattern (payments-platform-atc):** Table with 6 tools, each with specific purpose. "When a server you would have used is unavailable, tell the user what you would have checked and why."

### 3. Investigation Workflow (0-20)
- **20**: Multi-step workflow with decision trees ("Has request_id? → Yes → Query #1... No → What's the symptom?"). Steps are conditional, not mandatory sequential. References external docs/runbooks.
- **15**: Numbered steps with clear logic, but no conditional branching.
- **10**: Steps listed but no decision logic. Linear "do step 1, then step 2."
- **5**: Vague workflow ("gather context, then analyze").
- **0**: No workflow.

**Gold pattern (customer-account-triage):** Decision tree for query selection based on available identifiers. "These are not mandatory sequential steps. Decide what information you need."

### 4. SQL & Data Queries (0-15)
- **15**: Complete, runnable SQL with fully-qualified table names. Parameter placeholders clearly marked. Query result interpretation guidance ("if count > X, this means Y"). Multiple queries for different scenarios.
- **10**: SQL present with valid table refs, but no interpretation guidance.
- **5**: SQL fragments or pseudo-SQL. Table names mentioned but no complete queries.
- **0**: No data queries (acceptable for non-data skills — score N/A → 10).

**Gold pattern (meeting-prep):** 5 SQL blocks with FQ table names, parameter placeholders, and context for when to use each.

### 5. Output Format & Response Template (0-15)
- **15**: Structured output format with required vs optional sections. Guidance on when to include/exclude sections ("Shape the response to the problem. Not every section applies."). Classification taxonomy.
- **10**: Output format specified but no conditional inclusion logic.
- **5**: Generic "return a markdown summary."
- **0**: No output format specified.

**Gold pattern (payments-platform-atc):** Required sections (Summary, Owning Team, Classification, Recommended Action) + conditional sections (Root Cause, Evidence, Impact, Follow-up). Classification taxonomy with 6 categories.

### 6. Error Handling & Edge Cases (0-10)
- **10**: Explicit handling for: missing data, ambiguous inputs, tool failures, partial matches. "If context is missing, the draft should lead with clarifying questions."
- **7**: Handles 1-2 failure modes but misses common ones.
- **3**: Generic "if it fails, tell the user."
- **0**: No error handling.

**Gold pattern (customer-account-triage):** Step 1.5 "Check for Missing Context" — handles ambiguous account type, missing shop_id, unclear workflow. "If ambiguous → ask."

### 7. Anti-Gaming Quality Signals (0-15)
These are things that only genuinely good skills have — hard to fake with boilerplate:
- **Has domain-specific vocabulary** (not generic business terms) — e.g., "payment_reference_id starts with r + 24 alphanumeric chars"
- **Has negative instructions** ("You are NOT the ATC", "Don't assume NCA")
- **References specific file paths or docs** (references/observe_queries.md, not just "check docs")
- **Has a self-learning or improvement mechanism**
- **Handles the "looks similar but isn't" case** ("Similar error messages alone don't make a partial match")
- **15**: 4+ of the above signals present
- **10**: 2-3 signals
- **5**: 1 signal
- **0**: None — generic instructions that could apply to any domain
