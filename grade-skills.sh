#!/bin/bash
# grade-skills.sh — Revenue Skills Library Quality Grader
# Used with pi-autoresearch to continuously optimize skill quality
#
# Outputs: METRIC quality_score=N (0-100 composite)
# Also outputs secondary metrics for individual dimensions
#
# Usage: bash grade-skills.sh [skill_name]  (single skill)
#        bash grade-skills.sh               (all revenue skills)

set -euo pipefail

SKILLS_DIR="$HOME/.pi/agent-shopify/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Revenue skills we own (canonical list)
REVENUE_SKILLS=(
  prospect-researcher
  opp-compliance-checker
  account-research
  meeting-prep
  deal-followup
  opp-hygiene
  deal-prioritization
  daily-briefing
  competitive-positioning
  acquisition-sales
  sales-call-coach
  sales-writer
  sf-writer
  account-context-sync
  vertical-consumer-goods
  product-gap-tracker
  sales-manager-dashboard
  product-agentic
  product-headless
  qualification-trainer
  merchant-analytics-queries
  ae-se-collaboration
  summarize-last-call
  agentic-plan-sell
)

# Parking lot planned skills (not yet built)
PLANNED_SKILLS=(
  signal-monitor
  pitch-builder
  merchant-health-report
  context-handoff
  churn-intelligence
  vertical-battle-cards
)

# Account-related skills that MUST have UAL check
ACCOUNT_SKILLS=(
  prospect-researcher
  opp-compliance-checker
  account-research
  meeting-prep
  deal-followup
  opp-hygiene
  deal-prioritization
  qualification-trainer
)

# ─────────────────────────────────────────────────────────────
# DIMENSION 1: Skill Lint Score (0-40 points)
# Checks structure against METHODOLOGY.md standards
# ─────────────────────────────────────────────────────────────

lint_skill() {
  local skill_name="$1"
  local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
  local score=0
  local max=40
  local issues=""

  if [[ ! -f "$skill_file" ]]; then
    echo "0|$max|MISSING: $skill_file"
    return
  fi

  local content
  content=$(cat "$skill_file")

  # 1. Has YAML frontmatter with name + description (5 pts)
  if echo "$content" | head -1 | grep -q '^---'; then
    if echo "$content" | grep -q '^name:'; then
      score=$((score + 2))
    else
      issues="$issues|missing name in frontmatter"
    fi
    if echo "$content" | grep -q '^description:'; then
      score=$((score + 3))
    else
      issues="$issues|missing description in frontmatter"
    fi
  else
    issues="$issues|no YAML frontmatter"
  fi

  # 2. Description has trigger phrases (5 pts)
  local desc
  desc=$(awk '/^description:/{flag=1; sub(/^description: */,""); print} flag && /^  /{print} /^---/ && flag{flag=0}' "$skill_file" | tr '\n' ' ')
  local trigger_count=0
  for phrase in "Use when" "asked to" "when asked" "triggers on" "Works for"; do
    if echo "$desc" | grep -qi "$phrase"; then
      trigger_count=$((trigger_count + 1))
    fi
  done
  if [[ $trigger_count -ge 2 ]]; then
    score=$((score + 5))
  elif [[ $trigger_count -ge 1 ]]; then
    score=$((score + 3))
    issues="$issues|description could use more trigger phrases"
  else
    issues="$issues|description missing trigger phrases"
  fi

  # 3. Has Required Tools section (3 pts)
  if echo "$content" | grep -qi "require.*tool\|requires:.*\`\|Required Tools\|Requires:"; then
    score=$((score + 3))
  else
    issues="$issues|missing Required Tools section"
  fi

  # 4. Has Workflow with numbered steps (5 pts)
  local step_count=0
  step_count=$(grep -c '### Step' "$skill_file" 2>/dev/null || true)
  step_count=${step_count:-0}
  if [[ "$step_count" -ge 3 ]]; then
    score=$((score + 5))
  elif [[ "$step_count" -ge 1 ]]; then
    score=$((score + 3))
    issues="$issues|only $step_count workflow steps (want 3+)"
  else
    issues="$issues|no Step-based workflow"
  fi

  # 5. Has Output Template (4 pts)
  if echo "$content" | grep -qi "output template\|output format\|produces.*format\|## Output"; then
    score=$((score + 4))
  else
    issues="$issues|missing Output Template section"
  fi

  # 6. Has Error Handling (3 pts)
  if echo "$content" | grep -qi "error handling\|error.*fallback\|when.*fail\|if.*unavailable\|## Error"; then
    score=$((score + 3))
  else
    issues="$issues|missing Error Handling section"
  fi

  # 7. Has Anti-Patterns (2 pts)
  if echo "$content" | grep -qi "anti-pattern\|don't\|avoid\|never\|## Anti\|common mistake"; then
    score=$((score + 2))
  else
    issues="$issues|no anti-patterns documented"
  fi

  # 8. UAL-first for account skills (5 pts)
  local is_account_skill=false
  for s in "${ACCOUNT_SKILLS[@]}"; do
    if [[ "$skill_name" == "$s" ]]; then
      is_account_skill=true
      break
    fi
  done
  if $is_account_skill; then
    if echo "$content" | grep -qi "UAL\|unified_account_list\|ownership check\|Step 0"; then
      score=$((score + 5))
    else
      issues="$issues|ACCOUNT SKILL missing UAL-first check"
    fi
  else
    score=$((score + 5))  # N/A = full marks
  fi

  # 9. Has BQ query examples (3 pts)
  if echo "$content" | grep -q '```sql'; then
    score=$((score + 3))
  elif echo "$content" | grep -qi 'SELECT.*FROM\|query_bq\|BigQuery'; then
    score=$((score + 1))
    issues="$issues|mentions BQ but no SQL code block"
  else
    issues="$issues|no SQL/BQ query examples"
  fi

  # 10. Progressive data gathering (Layer 1→2→3) (5 pts)
  local layer_count=0
  echo "$content" | grep -qi "UAL\|ownership" && layer_count=$((layer_count + 1))
  echo "$content" | grep -qi "Salesforce\|salesforce_banff\|sales\.\|enriched" && layer_count=$((layer_count + 1))
  echo "$content" | grep -qi "signal\|smoke.*signal\|web.*search\|external\|Perplexity" && layer_count=$((layer_count + 1))
  if [[ $layer_count -ge 3 ]]; then
    score=$((score + 5))
  elif [[ $layer_count -ge 2 ]]; then
    score=$((score + 3))
    issues="$issues|only $layer_count data layers (want 3)"
  else
    score=$((score + 1))
    issues="$issues|only $layer_count data layer(s)"
  fi

  echo "$score|$max|${issues:-none}"
}

# ─────────────────────────────────────────────────────────────
# DIMENSION 2: Conciseness Score (0-15 points)
# Shorter is better, but not too short
# ─────────────────────────────────────────────────────────────

conciseness_score() {
  local skill_name="$1"
  local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "0|15|0"
    return
  fi

  local lines
  lines=$(wc -l < "$skill_file" | tr -d ' ')

  # Sweet spot: 80-200 lines. Too short = missing detail. Too long = bloated.
  local score=0
  if [[ $lines -ge 80 && $lines -le 150 ]]; then
    score=15  # perfect range
  elif [[ $lines -ge 60 && $lines -le 200 ]]; then
    score=12  # acceptable
  elif [[ $lines -ge 40 && $lines -le 300 ]]; then
    score=8   # needs work
  elif [[ $lines -ge 20 ]]; then
    score=4   # too short or too long
  else
    score=0   # stub
  fi

  echo "$score|15|$lines"
}

# ─────────────────────────────────────────────────────────────
# DIMENSION 3: BQ Query Validation (0-20 points)
# Extract SQL, dry-run against BigQuery
# ─────────────────────────────────────────────────────────────

bq_validation_score() {
  local skill_name="$1"
  local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "0|20|no file"
    return
  fi

  # Extract SQL blocks
  local sql_blocks
  sql_blocks=$(awk '/^```sql/{flag=1; next} /^```/{flag=0} flag' "$skill_file" 2>/dev/null)

  if [[ -z "$sql_blocks" ]]; then
    # No SQL = N/A, give partial credit if it's not an account/data skill
    echo "10|20|no SQL blocks (partial credit)"
    return
  fi

  # Count SQL blocks
  local block_count
  block_count=$(awk '/^```sql/{c++} END{print c+0}' "$skill_file")

  # Check for valid table references
  local valid_tables=0
  local total_tables=0
  for table in $(echo "$sql_blocks" | grep -oE '[a-z_-]+\.[a-z_-]+\.[a-z_-]+' | sort -u); do
    total_tables=$((total_tables + 1))
    # Known good prefixes
    if echo "$table" | grep -qE '^(shopify-dw|sdp-prd-commercial|sdp-for-analysts-platform)\.'; then
      valid_tables=$((valid_tables + 1))
    fi
  done

  local score=0
  if [[ $total_tables -eq 0 ]]; then
    score=10  # SQL exists but no FQ table refs — partial credit
    echo "$score|20|$block_count SQL blocks, no FQ table refs"
    return
  fi

  # Score based on % valid table refs
  local pct=$((valid_tables * 100 / total_tables))
  if [[ $pct -eq 100 ]]; then
    score=20
  elif [[ $pct -ge 75 ]]; then
    score=15
  elif [[ $pct -ge 50 ]]; then
    score=10
  else
    score=5
  fi

  echo "$score|20|$block_count SQL blocks, $valid_tables/$total_tables valid table refs"
}

# ─────────────────────────────────────────────────────────────
# DIMENSION 4: Coverage Score (0-15 points)
# What % of parking lot items are built?
# ─────────────────────────────────────────────────────────────

coverage_score() {
  local built=0
  local total=${#REVENUE_SKILLS[@]}
  local planned_total=${#PLANNED_SKILLS[@]}

  for skill in "${REVENUE_SKILLS[@]}"; do
    if [[ -d "$SKILLS_DIR/$skill" ]]; then
      built=$((built + 1))
    fi
  done

  local planned_built=0
  for skill in "${PLANNED_SKILLS[@]}"; do
    if [[ -d "$SKILLS_DIR/$skill" ]]; then
      planned_built=$((planned_built + 1))
    fi
  done

  local all_total=$((total + planned_total))
  local all_built=$((built + planned_built))
  local pct=$((all_built * 100 / all_total))

  local score=0
  if [[ $pct -ge 90 ]]; then
    score=15
  elif [[ $pct -ge 80 ]]; then
    score=13
  elif [[ $pct -ge 70 ]]; then
    score=11
  elif [[ $pct -ge 60 ]]; then
    score=9
  elif [[ $pct -ge 50 ]]; then
    score=7
  else
    score=$((pct * 15 / 100))
  fi

  echo "$score|15|$all_built/$all_total skills exist ($pct%)"
}

# ─────────────────────────────────────────────────────────────
# DIMENSION 5: Simulation Readiness (0-10 points)
# Can an agent actually execute this skill end-to-end?
# ─────────────────────────────────────────────────────────────

simulation_readiness() {
  local skill_name="$1"
  local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "0|10|no file"
    return
  fi

  local content
  content=$(cat "$skill_file")
  local score=0

  # 1. Has a concrete example invocation (3 pts)
  if echo "$content" | grep -qiE '"(prep me|research|check|analyze|coach|draft|update|show me|what|who|how)'; then
    score=$((score + 3))
  elif echo "$content" | grep -qi "example\|invocation\|trigger"; then
    score=$((score + 1))
  fi

  # 2. Has a real table/tool that exists (3 pts)
  if echo "$content" | grep -qE '(shopify-dw|sdp-prd|sdp-for-analysts|query_bq|agent-data|perplexity|web_search|slack_search|gmail_read)'; then
    score=$((score + 3))
  fi

  # 3. Output is copy-paste ready (2 pts)
  if echo "$content" | grep -qiE '(markdown table|##.*output|format.*response|structured.*output|copy.paste)'; then
    score=$((score + 2))
  fi

  # 4. Has a clear "done" state (2 pts)
  if echo "$content" | grep -qiE '(deliver|present|final.*output|hand.*off|return.*to.*user|summary)'; then
    score=$((score + 2))
  fi

  echo "$score|10|simulation readiness"
}

# ─────────────────────────────────────────────────────────────
# MAIN: Grade all skills and output composite metric
# ─────────────────────────────────────────────────────────────

if [[ $# -eq 1 ]]; then
  # Single skill mode
  SKILLS_TO_GRADE=("$1")
else
  SKILLS_TO_GRADE=("${REVENUE_SKILLS[@]}")
fi

total_score=0
total_max=0
skill_count=0
all_lint=0
all_concise=0
all_bq=0
all_sim=0

echo "═══════════════════════════════════════════════════════════════"
echo "  Revenue Skills Library — Quality Report"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for skill in "${SKILLS_TO_GRADE[@]}"; do
  if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
    continue
  fi

  # Run all dimensions
  IFS='|' read -r lint_s lint_m lint_issues <<< "$(lint_skill "$skill")"
  IFS='|' read -r con_s con_m con_lines <<< "$(conciseness_score "$skill")"
  IFS='|' read -r bq_s bq_m bq_detail <<< "$(bq_validation_score "$skill")"
  IFS='|' read -r sim_s sim_m sim_detail <<< "$(simulation_readiness "$skill")"

  skill_total=$((lint_s + con_s + bq_s + sim_s))
  skill_max=$((lint_m + con_m + bq_m + sim_m))
  skill_pct=$((skill_total * 100 / skill_max))

  # Emoji rating
  local_emoji="🟢"
  [[ $skill_pct -lt 80 ]] && local_emoji="🟡"
  [[ $skill_pct -lt 60 ]] && local_emoji="🔴"

  printf "%s %-28s %3d/%d (%2d%%)  lint=%2d con=%2d bq=%2d sim=%2d" \
    "$local_emoji" "$skill" "$skill_total" "$skill_max" "$skill_pct" \
    "$lint_s" "$con_s" "$bq_s" "$sim_s"

  if [[ "$lint_issues" != "none" && -n "$lint_issues" ]]; then
    # Show first issue only
    first_issue=$(echo "$lint_issues" | tr '|' '\n' | head -2 | tail -1)
    printf "  ← %s" "$first_issue"
  fi
  echo ""

  total_score=$((total_score + skill_total))
  total_max=$((total_max + skill_max))
  all_lint=$((all_lint + lint_s))
  all_concise=$((all_concise + con_s))
  all_bq=$((all_bq + bq_s))
  all_sim=$((all_sim + sim_s))
  skill_count=$((skill_count + 1))
done

echo ""
echo "───────────────────────────────────────────────────────────────"

# Coverage (global, not per-skill)
IFS='|' read -r cov_s cov_m cov_detail <<< "$(coverage_score)"
total_score=$((total_score + cov_s))
total_max=$((total_max + cov_m))

echo "📊 Coverage: $cov_detail → $cov_s/$cov_m pts"

# Final composite
if [[ $total_max -gt 0 ]]; then
  composite=$((total_score * 100 / total_max))
else
  composite=0
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
printf "  COMPOSITE SCORE: %d/%d (%d%%)\n" "$total_score" "$total_max" "$composite"
echo "  Skills graded: $skill_count | Coverage: $cov_detail"
echo "═══════════════════════════════════════════════════════════════"

# Autoresearch-compatible metric output
echo ""
echo "METRIC quality_score=$composite"
echo "METRIC lint_score=$((all_lint * 100 / (skill_count * 40)))"
echo "METRIC conciseness_score=$((all_concise * 100 / (skill_count * 15)))"
echo "METRIC bq_score=$((all_bq * 100 / (skill_count * 20)))"
echo "METRIC sim_score=$((all_sim * 100 / (skill_count * 10)))"
echo "METRIC coverage_pct=$((cov_s * 100 / cov_m))"
echo "METRIC skills_graded=$skill_count"
