#!/bin/bash
# autoresearch.sh — Eval harness for csm-portfolio-triage autoresearch loop
# Pulls real data from CS Compass Quick.db, runs 4 scenario tests, outputs METRIC lines
#
# Usage: bash autoresearch.sh
# Expected duration: ~60s per run

set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/SKILL.md"
EVAL_DIR="$SCRIPT_DIR/eval"

# Pre-check
if [ ! -f "$SKILL_FILE" ]; then
  echo "METRIC quality_score=0"
  echo "ERROR: SKILL.md not found"
  exit 1
fi

LINES=$(wc -l < "$SKILL_FILE")
if [ "$LINES" -gt 500 ]; then
  echo "METRIC quality_score=0"
  echo "ERROR: SKILL.md is $LINES lines (max 500)"
  exit 1
fi

# Step 1: Pull real data from CS Compass
quick mcp cs-compass <<'QEOF' > /tmp/eval-mitigations-raw.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"risk_mitigation_actions","limit":50}},"id":1}
QEOF

quick mcp cs-compass <<'QEOF' > /tmp/eval-rhs-raw.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"rhs_portfolio_cache","limit":1}},"id":1}
QEOF

quick mcp cs-compass <<'QEOF' > /tmp/eval-risk-overrides.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"risk_overrides","limit":20}},"id":1}
QEOF

# Step 2: Build test data
python3 "$EVAL_DIR/build_test_data.py" > "$EVAL_DIR/real_test_data.json"
python3 "$EVAL_DIR/build_additional_tests.py"

SKILL_CONTENT=$(head -500 "$SKILL_FILE")
BASE_DATA=$(cat "$EVAL_DIR/real_test_data.json" | head -c 8000)
ADD_TESTS="$EVAL_DIR/additional_test_cases.json"

# Step 3: Run Scenario 1 — base real-data eval
S1_PAYLOAD=$(python3 "$EVAL_DIR/build_prompt.py")
S1_RESP=$(curl -s -X POST "https://proxy.shopify.ai/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: $PI_PROXY_AUTH_HEADER" \
  -d "$S1_PAYLOAD")

S1=$(echo "$S1_RESP" | python3 -c "
import json, sys, re
resp = json.load(sys.stdin)
content = resp.get('choices', [{}])[0].get('message', {}).get('content', '')
match = re.search(r'\{[^{}]+\}', content, re.DOTALL)
if match:
    d = json.loads(match.group())
    print(d.get('score', 0))
else:
    print(0)
" 2>/dev/null || echo 0)

# Step 4: Run Scenarios 2-4
run_scenario() {
  local NUM=$1
  local IDX=$((NUM - 2))
  
  local TEST_CASE
  TEST_CASE=$(python3 -c "
import json
data = json.load(open('$ADD_TESTS'))
tc = data['test_cases'][$IDX]
print(json.dumps(tc, default=str))
" 2>/dev/null)
  
  local CHECKS
  CHECKS=$(python3 -c "
import json
data = json.load(open('$ADD_TESTS'))
tc = data['test_cases'][$IDX]
print('\n'.join('- ' + c for c in tc.get('validation_checks', [])))
" 2>/dev/null)

  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json, sys
skill = open('$SKILL_FILE').read()[:8000]
tc = '''$TEST_CASE'''[:6000]
checks = '''$CHECKS'''
prompt = 'Evaluate this skill against the test scenario.\n\nSKILL.md:\n' + skill + '\n\nTEST SCENARIO:\n' + tc + '\n\nVALIDATION CHECKS:\n' + checks + '\n\nScore 0-100. Return ONLY JSON: {\"score\": N, \"checks_passed\": N, \"checks_total\": N, \"gaps\": \"specific gaps\"}'
json.dump({'model': 'claude-haiku-4-5', 'max_tokens': 800, 'messages': [{'role': 'user', 'content': prompt}]}, sys.stdout)
" 2>/dev/null)

  local RESP
  RESP=$(curl -s -X POST "https://proxy.shopify.ai/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: $PI_PROXY_AUTH_HEADER" \
    -d "$PAYLOAD")

  echo "$RESP" | python3 -c "
import json, sys, re
resp = json.load(sys.stdin)
content = resp.get('choices', [{}])[0].get('message', {}).get('content', '')
match = re.search(r'\{[^{}]+\}', content, re.DOTALL)
if match:
    d = json.loads(match.group())
    print(d.get('score', 0))
else:
    print(0)
" 2>/dev/null || echo 0
}

S2=$(run_scenario 2)
S3=$(run_scenario 3)
S4=$(run_scenario 4)

# Step 5: Composite
COMPOSITE=$(python3 -c "
s = [int('${S1:-0}'), int('${S2:-0}'), int('${S3:-0}'), int('${S4:-0}')]
print(round(sum(s) / len(s)))
")

echo "METRIC quality_score=$COMPOSITE"
echo "METRIC scenario_1_base=$S1"
echo "METRIC scenario_2_csm_portfolio=$S2"
echo "METRIC scenario_3_risk_overrides=$S3"
echo "METRIC scenario_4_rhs_distribution=$S4"
echo "METRIC lines=$LINES"
