#!/bin/bash
# run_eval.sh — Evaluate csm-portfolio-triage against real CS Compass data
# Pulls live data from Quick.db, grades skill with LLM judge
#
# Usage: bash eval/run_eval.sh
# Outputs: METRIC quality_score=N

set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
EVAL_DATA="$SCRIPT_DIR/real_test_data.json"

echo "=== CSM Portfolio Triage Eval (Real Data) ==="

# Step 1: Pull real data from CS Compass Quick.db
echo "Step 1: Pulling live data from CS Compass..."
quick mcp cs-compass <<'QEOF' > /tmp/eval-mitigations-raw.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"risk_mitigation_actions","limit":50}},"id":1}
QEOF

quick mcp cs-compass <<'QEOF' > /tmp/eval-rhs-raw.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"rhs_portfolio_cache","limit":1}},"id":1}
QEOF

quick mcp cs-compass <<'QEOF' > /tmp/eval-risk-overrides.json 2>/dev/null
{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_collection","arguments":{"collection":"risk_overrides","limit":20}},"id":1}
QEOF

# Step 2: Build test dataset
echo "Step 2: Building test dataset..."
python3 "$SCRIPT_DIR/build_test_data.py" > "$EVAL_DATA"
echo "  $(python3 -c "import json; d=json.load(open('$EVAL_DATA')); print(f'Accounts: {d[\"total_mitigation_accounts\"]} with mitigations, {d[\"total_rhs_accounts\"]} in RHS')")"
echo "  $(python3 -c "import json; d=json.load(open('$EVAL_DATA')); r=d['rhs_distribution']; print(f'Distribution: {r[\"healthy\"]} healthy, {r[\"atrophying\"]} atrophying, {r[\"at_risk\"]} at risk')")"

# Step 3: Grade with LLM judge
echo "Step 3: Grading against real data..."
PAYLOAD=$(python3 "$SCRIPT_DIR/build_prompt.py")

RESPONSE=$(curl -s -X POST "https://proxy.shopify.ai/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: $PI_PROXY_AUTH_HEADER" \
  -d "$PAYLOAD")

echo ""
echo "$RESPONSE" | python3 "$SCRIPT_DIR/parse_response.py"
echo ""
echo "=== Eval complete ==="
