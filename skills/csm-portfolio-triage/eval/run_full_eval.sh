#!/bin/bash
# run_full_eval.sh — Full 4-scenario eval for csm-portfolio-triage
# Runs: base real-data eval + 3 additional scenario tests
# Outputs: METRIC lines for each scenario + composite score

set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_FILE="$SKILL_DIR/SKILL.md"

echo "═══════════════════════════════════════════════════════"
echo "  CSM Portfolio Triage — Full Eval (4 scenarios)"
echo "═══════════════════════════════════════════════════════"
echo ""

# === Scenario 1: Base real-data eval ===
echo "━━━ Scenario 1: Base real-data eval ━━━"
bash "$SCRIPT_DIR/run_eval.sh" 2>&1 | tee /tmp/eval-scenario1.log
S1=$(grep "METRIC quality_score" /tmp/eval-scenario1.log | head -1 | grep -o '[0-9]*')
echo ""

# === Scenarios 2-4: Additional test cases ===
# Pull fresh data if not already available
if [ ! -f "$SCRIPT_DIR/real_test_data.json" ]; then
  echo "ERROR: Run run_eval.sh first to generate real_test_data.json"
  exit 1
fi

# Generate additional test cases from real data
python3 "$SCRIPT_DIR/build_additional_tests.py"

ADDITIONAL_TESTS="$SCRIPT_DIR/additional_test_cases.json"
SKILL_CONTENT=$(head -500 "$SKILL_FILE")

for SCENARIO_NUM in 2 3 4; do
  SCENARIO_IDX=$((SCENARIO_NUM - 2))
  
  # Extract this test case
  TEST_CASE=$(python3 -c "
import json
data = json.load(open('$ADDITIONAL_TESTS'))
tc = data['test_cases'][$SCENARIO_IDX]
print(json.dumps(tc, indent=2, default=str))
")
  
  TEST_ID=$(echo "$TEST_CASE" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  TEST_DESC=$(echo "$TEST_CASE" | python3 -c "import json,sys; print(json.load(sys.stdin)['description'][:80])")
  
  echo "━━━ Scenario $SCENARIO_NUM: $TEST_DESC ━━━"
  
  # Build prompt for this scenario
  PAYLOAD=$(python3 -c "
import json, sys

skill = open('$SKILL_FILE').read()[:8000]
test_case = json.loads('''$TEST_CASE''')
checks = test_case.get('validation_checks', [])

prompt = '''You are evaluating a Customer Success portfolio triage skill against a specific test scenario.

SKILL.md:
''' + skill + '''

TEST SCENARIO:
''' + json.dumps(test_case, indent=2, default=str)[:6000] + '''

VALIDATION CHECKS (the skill must pass these):
''' + chr(10).join(f'- {c}' for c in checks) + '''

Score the skill on this specific scenario (0-100):
- How many validation checks would the skill pass? (0-40)
- Does the skill handle the specific data patterns in this scenario? (0-30) 
- Would the output be useful to a real CSM/Lead in this situation? (0-30)

Return ONLY JSON: {\"score\": N, \"checks_passed\": N, \"checks_total\": N, \"data_handling\": N, \"usefulness\": N, \"gaps\": \"specific gaps for this scenario\"}'''

payload = {
    'model': 'claude-haiku-4-5',
    'max_tokens': 800,
    'messages': [{'role': 'user', 'content': prompt}]
}
json.dump(payload, sys.stdout)
")
  
  RESPONSE=$(curl -s -X POST "https://proxy.shopify.ai/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: $PI_PROXY_AUTH_HEADER" \
    -d "$PAYLOAD")
  
  SCORE=$(echo "$RESPONSE" | python3 -c "
import json, sys, re
resp = json.load(sys.stdin)
content = resp.get('choices', [{}])[0].get('message', {}).get('content', '')
match = re.search(r'\{[^{}]+\}', content, re.DOTALL)
if match:
    d = json.loads(match.group())
    score = d.get('score', 0)
    passed = d.get('checks_passed', '?')
    total = d.get('checks_total', '?')
    gaps = d.get('gaps', 'none')
    print(f'METRIC scenario_${SCENARIO_NUM}_score={score}')
    print(f'  Checks: {passed}/{total} passed')
    print(f'  Gaps: {gaps}')
else:
    print(f'METRIC scenario_${SCENARIO_NUM}_score=0')
    print(f'  ERROR: Could not parse: {content[:200]}')
" 2>&1)
  
  echo "$SCORE"
  eval "S${SCENARIO_NUM}=\$(echo '$SCORE' | grep 'METRIC scenario' | grep -o '[0-9]*')"
  echo ""
done

# === Composite Score ===
echo "═══════════════════════════════════════════════════════"
echo "  RESULTS SUMMARY"
echo "═══════════════════════════════════════════════════════"
echo "  Scenario 1 (Base real-data):      ${S1:-0}/100"
echo "  Scenario 2 (Single CSM portfolio): ${S2:-0}/100"
echo "  Scenario 3 (Risk overrides):       ${S3:-0}/100"
echo "  Scenario 4 (RHS distribution):     ${S4:-0}/100"

# Compute average
COMPOSITE=$(python3 -c "
s = [int('${S1:-0}'), int('${S2:-0}'), int('${S3:-0}'), int('${S4:-0}')]
print(round(sum(s) / len(s)))
")
echo ""
echo "  COMPOSITE: $COMPOSITE/100"
echo "═══════════════════════════════════════════════════════"
echo "METRIC composite_score=$COMPOSITE"
