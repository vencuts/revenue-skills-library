#!/usr/bin/env python3
"""Build the LLM judge prompt for csm-portfolio-triage eval."""
import json
import sys
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
skill_dir = os.path.dirname(script_dir)
skill_file = os.path.join(skill_dir, "SKILL.md")
eval_data = os.path.join(script_dir, "real_test_data.json")

skill_content = open(skill_file).read()[:8000]
test_data = open(eval_data).read()[:8000]

prompt = """You are evaluating a Customer Success portfolio triage skill. You have:
1. The skill's SKILL.md (instructions for an AI agent)
2. Real production data from Shopify's CS Compass tool (8,000+ accounts)

Grade the skill on how well it would handle this real data. Score each dimension:

DIMENSIONS (total 100):
1. Data Handling (0-20): Does the skill correctly reference the tables, fields, and query patterns that would produce this data? Would the SQL actually work against these real accounts?
2. Classification Accuracy (0-20): Given these real at-risk accounts with known risk flags (Negative YoY, QoQ Decline, Support Spike, etc.), would the skill's decision tree correctly classify them?
3. Actionability (0-20): For these real accounts with real GMV ($180K-$73M range), real risk scores (0-29), and real segments, would the suggested actions be useful to a CSM?
4. Edge Case Coverage (0-20): The real data includes: accounts with mitigation actions in progress, risk overrides by leads, accounts in multiple segments, CSMs with 1-6 flagged accounts. Does the skill handle these?
5. Domain Accuracy (0-20): Does the skill use correct CS terminology, segment names, risk flag names, and engagement targets that match what CS Compass actually uses?

Return ONLY a JSON object, no markdown fences:
{"score": N, "d1_data": N, "d2_classification": N, "d3_actionability": N, "d4_edge_cases": N, "d5_domain": N, "gaps": "top 3 gaps", "strengths": "top 3 strengths"}"""

message = f"SKILL.md:\n{skill_content}\n\nREAL DATA:\n{test_data}\n\n{prompt}"

payload = {
    "model": "claude-haiku-4-5",
    "max_tokens": 1000,
    "messages": [{"role": "user", "content": message}]
}

json.dump(payload, sys.stdout)
