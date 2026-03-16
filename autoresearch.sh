#!/bin/bash
# autoresearch.sh — LLM-as-Judge grading for Revenue Skills Library
# Called by pi-autoresearch extension. Outputs METRIC lines.
#
# Uses Shopify AI proxy to score skills against rubric.md
# Cost: ~$0.05-0.15 per skill per run (claude-haiku)
#
# Usage: bash autoresearch.sh                    # grade all revenue skills
#        bash autoresearch.sh prospect-researcher # grade single skill

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.pi/agent/skills"
RUBRIC_FILE="$SCRIPT_DIR/rubric.md"
RESULTS_FILE="$SCRIPT_DIR/autoresearch-scores.json"

# Shopify AI proxy endpoint — uses Pi's proxy auth
AI_PROXY="https://proxy.shopify.ai/v1/chat/completions"
AUTH_HEADER="${PI_PROXY_AUTH_HEADER:-}"
# Use haiku for fast/cheap judging
MODEL="claude-haiku-4-5"

if [[ -z "$AUTH_HEADER" ]]; then
  echo "ERROR: PI_PROXY_AUTH_HEADER not set. Run from Pi terminal or export it."
  exit 1
fi

# Revenue skills to grade
ALL_SKILLS=(
  prospect-researcher opp-compliance-checker account-research meeting-prep
  deal-followup opp-hygiene deal-prioritization daily-briefing
  competitive-positioning acquisition-sales sales-call-coach sales-writer
  sf-writer account-context-sync vertical-consumer-goods product-gap-tracker
  sales-manager-dashboard product-agentic qualification-trainer
  merchant-analytics-queries ae-se-collaboration summarize-last-call agentic-plan-sell
  techstack-fingerprint data-integrity-check revenue-data-research
)

# Determine which skills to grade
if [[ $# -eq 1 ]]; then
  SKILLS_TO_GRADE=("$1")
else
  SKILLS_TO_GRADE=("${ALL_SKILLS[@]}")
fi

# Read rubric
RUBRIC=$(cat "$RUBRIC_FILE")

# ─────────────────────────────────────────────────────────────
# Grade a single skill via LLM
# ─────────────────────────────────────────────────────────────
grade_skill() {
  local skill_name="$1"
  local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo '{"skill":"'"$skill_name"'","score":0,"reason":"SKILL.md not found"}'
    return
  fi

  local skill_content
  skill_content=$(cat "$skill_file" | head -500)  # cap at 500 lines to fit context

  # Build the prompt
  local system_prompt='You are a skill quality judge. Score the given SKILL.md against the rubric. Return ONLY a JSON object with these fields:
- "score": integer 0-100 (composite of all rubric dimensions)
- "d1_problem": integer 0-15 (Problem Definition & Scope)
- "d2_tools": integer 0-10 (Tool & Data Source Specification)
- "d3_workflow": integer 0-20 (Investigation Workflow)
- "d4_sql": integer 0-15 (SQL & Data Queries)
- "d5_output": integer 0-15 (Output Format & Response Template)
- "d6_errors": integer 0-10 (Error Handling & Edge Cases)
- "d7_quality": integer 0-15 (Anti-Gaming Quality Signals)
- "top_gap": string (the single most impactful improvement this skill needs)
- "reason": string (1-2 sentence justification)

Be strict. A score of 70+ means genuinely good. 90+ means gold-standard quality. Do NOT inflate scores. Return ONLY the JSON object, no markdown fences.'

  local user_prompt="## RUBRIC
$RUBRIC

## SKILL TO GRADE: $skill_name
$skill_content"

  # Escape for JSON payload
  local escaped_system
  escaped_system=$(printf '%s' "$system_prompt" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
  local escaped_user
  escaped_user=$(printf '%s' "$user_prompt" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

  # Call AI proxy
  local response
  response=$(curl -s --max-time 60 "$AI_PROXY" \
    -H "Content-Type: application/json" \
    -H "Authorization: ${AUTH_HEADER}" \
    -d '{
      "model": "'"$MODEL"'",
      "messages": [
        {"role": "system", "content": '"$escaped_system"'},
        {"role": "user", "content": '"$escaped_user"'}
      ],
      "max_tokens": 500,
      "temperature": 0.1
    }' 2>/dev/null)

  # Extract the content
  local content
  content=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    text = data['choices'][0]['message']['content']
    # Strip markdown fences if present
    text = text.strip()
    if text.startswith('\`\`\`'):
        text = text.split('\n', 1)[1] if '\n' in text else text
        if text.endswith('\`\`\`'):
            text = text[:-3]
        text = text.strip()
    # Validate it's JSON
    parsed = json.loads(text)
    parsed['skill'] = '$skill_name'
    print(json.dumps(parsed))
except Exception as e:
    print(json.dumps({'skill': '$skill_name', 'score': 0, 'reason': f'Parse error: {e}', 'top_gap': 'unknown'}))
" 2>/dev/null)

  echo "$content"
}

# ─────────────────────────────────────────────────────────────
# Main: Grade skills and compute metrics
# ─────────────────────────────────────────────────────────────

total_score=0
skill_count=0
all_results=()

echo "═══════════════════════════════════════════════════════════════"
echo "  Revenue Skills Library — LLM Judge Report"
echo "  $(date '+%Y-%m-%d %H:%M') | Model: $MODEL"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for skill in "${SKILLS_TO_GRADE[@]}"; do
  if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
    continue
  fi

  # Grade via LLM
  result=$(grade_skill "$skill")
  all_results+=("$result")

  # Extract score
  score=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('score',0))" 2>/dev/null || echo 0)
  top_gap=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('top_gap','unknown'))" 2>/dev/null || echo "unknown")

  # Emoji rating
  emoji="🟢"
  [[ $score -lt 70 ]] && emoji="🟡"
  [[ $score -lt 50 ]] && emoji="🔴"

  printf "%s %-28s %3d/100  ← %s\n" "$emoji" "$skill" "$score" "$top_gap"

  total_score=$((total_score + score))
  skill_count=$((skill_count + 1))
done

echo ""
echo "───────────────────────────────────────────────────────────────"

# Compute averages
if [[ $skill_count -gt 0 ]]; then
  avg_score=$((total_score / skill_count))
else
  avg_score=0
fi

# Save detailed results
echo "[" > "$RESULTS_FILE"
first=true
for r in "${all_results[@]}"; do
  if $first; then first=false; else echo "," >> "$RESULTS_FILE"; fi
  echo "  $r" >> "$RESULTS_FILE"
done
echo "]" >> "$RESULTS_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════════"
printf "  AVERAGE SCORE: %d/100 (%d skills graded)\n" "$avg_score" "$skill_count"
echo "  Detailed results: $RESULTS_FILE"
echo "═══════════════════════════════════════════════════════════════"

# Autoresearch-compatible metric output
echo ""
echo "METRIC quality_score=$avg_score"
echo "METRIC skills_graded=$skill_count"
