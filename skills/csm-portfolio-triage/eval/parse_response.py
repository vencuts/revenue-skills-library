#!/usr/bin/env python3
"""Parse LLM judge response and output METRIC lines."""
import json
import re
import sys
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
eval_output = os.path.join(script_dir, "eval_output.json")

resp = json.load(sys.stdin)
content = resp.get("choices", [{}])[0].get("message", {}).get("content", "")

# Find JSON in response
match = re.search(r'\{[^{}]+\}', content, re.DOTALL)
if match:
    d = json.loads(match.group())
    print(f'METRIC quality_score={d["score"]}')
    print(f'METRIC d1_data={d["d1_data"]}')
    print(f'METRIC d2_classification={d["d2_classification"]}')
    print(f'METRIC d3_actionability={d["d3_actionability"]}')
    print(f'METRIC d4_edge_cases={d["d4_edge_cases"]}')
    print(f'METRIC d5_domain={d["d5_domain"]}')
    print(f'GAPS: {d.get("gaps", "none")}')
    print(f'STRENGTHS: {d.get("strengths", "none")}')
    json.dump(d, open(eval_output, "w"), indent=2)
else:
    print("METRIC quality_score=0")
    print(f"ERROR: Could not parse response: {content[:300]}")
