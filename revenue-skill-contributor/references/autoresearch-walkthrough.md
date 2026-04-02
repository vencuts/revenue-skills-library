# Autoresearch Walkthrough — Step by Step

⚠️ **This guide assumes some comfort with git and the terminal.** If anything below is confusing, that's OK — stop and tell your AI agent "I don't understand [X]" and it will explain. Or choose Option A (submit without autoresearch) and the core team will handle this part.

---

## What Autoresearch Does

Autoresearch is an autonomous improvement loop. It:
1. Picks the weakest part of your skill
2. Makes a small, targeted edit
3. Runs the skill against test cases
4. Scores the output with a blind judge (who never sees your SKILL.md)
5. If the score improved → keeps the change
6. If the score dropped → reverts the change
7. Repeats

This typically runs for 10-30 iterations and can push a skill from 65 → 78+.

---

## Step 1: Create a git branch

We work on a separate branch so your original skill is always safe.

Tell your AI agent:
> "Create a git branch for autoresearch on my [skill-name] skill"

The agent will run:
```bash
cd [wherever your skill lives]
git checkout -b autoresearch/[skill-name]-$(date +%Y%m%d)
```

---

## Step 2: Create blind test cases

Blind test cases are scenarios where:
- The **input** is a realistic task (e.g., "Analyze why we lost the Acme Corp deal")
- The **expected output** describes what a good answer looks like
- The **judge** scores the output WITHOUT seeing the skill's instructions

Your AI agent will draft 3-5 test cases. **You validate them:**
- "Does this scenario make sense for my workflow?"
- "Is the expected output realistic?"
- "Would I actually ask this question?"

The agent saves these to `evals/evals.json` in your skill directory.

### What makes a good test case

| Good | Bad |
|------|-----|
| Specific entity: "Analyze opp 0061234 (Collectible Brands)" | Generic: "Analyze a deal" |
| Verifiable output: "Must mention the 3 calls that happened in March" | Vague: "Should be helpful" |
| Edge case: "Opp with no calls and no emails" | Only happy path |

You want at least:
1. **Happy path** — full data available, standard scenario
2. **Sparse data** — missing calls, missing emails, incomplete opp
3. **Edge case** — something specific to your domain (e.g., deal that switched owners, opp with no stage dates)

---

## Step 3: Set up the autoresearch files

The agent creates two files:

### `autoresearch.md` — The experiment plan
Describes what we're optimizing, what the metric is, what files are in scope, and what's been tried. A fresh agent can read this file and continue the loop.

### `autoresearch.sh` — The benchmark script
Runs the skill against test cases, scores the output, and prints `METRIC combined_score=X` lines. This is what the loop uses to decide keep/discard.

The agent will show you both files. You don't need to edit them — just confirm they look reasonable.

---

## Step 4: Run the baseline

The agent runs the benchmark once to establish the starting score.

> "Running baseline... Your skill currently scores [X]/100 (combined). This is the number we're trying to improve."

---

## Step 5: Start the loop

Tell your agent:
> "Start the autoresearch loop"

The agent will now run autonomously:
1. Read the current skill and scores
2. Identify the weakest dimension
3. Make ONE targeted edit
4. Re-run the benchmark
5. If improved → commit the change (keep)
6. If worse → revert the change (discard)
7. Log what was tried
8. Repeat

**You can walk away.** The loop runs until you interrupt it or it plateaus (2 consecutive no-improvement iterations).

---

## Step 6: Review results

When the loop finishes (or you stop it), the agent will show you:

```
AUTORESEARCH RESULTS
====================
Started: [score]/100
Final:   [score]/100
Iterations: [N]
Kept: [N]  Discarded: [N]  Crashed: [N]

Key improvements:
- Iteration 3: Added error handling for missing calls (+4 pts)
- Iteration 7: Improved SQL date alignment (+2 pts)
- Iteration 12: Added conditional output for sparse data (+3 pts)

Dead ends:
- Iteration 5: Tried adding competitor analysis (reverted, -1 pt)
- Iteration 9: Tried verbose output format (reverted, no change)
```

### What to check

1. **Do the kept changes make sense?** Read the diff for each kept iteration.
2. **Is the output still correct?** Run the skill against your known-good entity from Phase 2.
3. **Did it improve genuinely or game the scoring?** If the blind test scores jumped but the output looks weird, it may have optimized for the test cases rather than real quality. Flag this.

---

## Step 7: Finalize

If you're happy with the improvements:
> "Keep the autoresearch changes and proceed to submission"

If something went wrong:
> "Revert all autoresearch changes and go back to the pre-autoresearch version"

Either way, you now proceed to Phase 4 (Package & Submit) in the main skill.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Git checkout failed" | Make sure you saved any uncommitted work first |
| "Benchmark script errored" | Tell the agent — it'll fix the script and retry |
| "Score isn't improving" | After 5 iterations of no improvement, the agent should stop and suggest manual improvements |
| "I don't understand what happened" | Ask the agent to explain each kept change in plain language |
| "I want to stop" | Just tell the agent "stop autoresearch" — it'll preserve the current state |
