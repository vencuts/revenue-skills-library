#!/usr/bin/env python3
"""Build 3 additional test cases from real CS Compass data."""
import json
import os
from datetime import datetime

script_dir = os.path.dirname(os.path.abspath(__file__))
data = json.load(open(os.path.join(script_dir, "real_test_data.json")))
accounts = data['test_accounts']
rhs = data['rhs_distribution']
overrides = data['risk_overrides']

# Test 2: Single CSM portfolio
csm_books = {}
for a in accounts:
    csm = a.get('csm_email', 'unknown')
    csm_books.setdefault(csm, []).append(a)

best_csm = max(csm_books.items(), key=lambda x: len(x[1]))
test2 = {
    "id": "test_2_single_csm_real_portfolio",
    "description": f"Real CSM portfolio: {best_csm[0]} ({len(best_csm[1])} flagged accounts, {best_csm[1][0].get('segment')} segment)",
    "csm_email": best_csm[0],
    "segment": best_csm[1][0].get('segment'),
    "lead": best_csm[1][0].get('lead_name'),
    "accounts": best_csm[1],
    "validation_checks": [
        f"Must identify {len(best_csm[1])} accounts with active risk flags",
        f"Must use {best_csm[1][0].get('segment')} engagement targets",
        "Must list specific risk flags per account from the 21-flag taxonomy",
        "Must check for active mitigations before recommending new actions",
        "Must NOT recommend creating duplicate mitigation actions for accounts with status != draft",
        "Must show risk_score/29 for each account",
        "Must handle conflict between sf_risk_level='Low' and risk_category='CRITICAL'"
    ]
}

# Test 3: Risk overrides
test3 = {
    "id": "test_3_risk_overrides",
    "description": f"{len(overrides)} accounts have lead-approved risk overrides",
    "overrides": overrides,
    "validation_checks": [
        "Must check risk_overrides collection before finalizing classification",
        "Must surface override info: who approved, what flags were addressed",
        "Must NOT flag an overridden account as Act Now if override is active",
        "Must note expired overrides",
        "Must handle reactivated overrides",
        "Must show both automated risk_category and override when they differ",
    ]
}

# Test 4: RHS distribution stress
test4 = {
    "id": "test_4_rhs_distribution_stress",
    "description": f"RHS: {rhs['at_risk']} At Risk (49%), {rhs['atrophying']} Atrophying (42%), {rhs['healthy']} Healthy (9%)",
    "distribution": rhs,
    "total_accounts": data['total_rhs_accounts'],
    "validation_checks": [
        "Must NOT classify all At Risk accounts as Act Now — would be 4000+ accounts",
        "Must use risk_score to differentiate within At Risk tier",
        "Must recognize Atrophying as distinct from At Risk",
        "For a 20-50 account portfolio, aim for 3-5 Act Now, 5-10 Monitor, rest Healthy",
        "Must prioritize auto-critical flags first, then high risk_score + disengaged",
        "Must not produce alert fatigue — wall of red is useless",
        "RHS At Risk is NOT the same as risk_category CRITICAL/HIGH",
    ]
}

output = {
    "generated_at": datetime.now().isoformat(),
    "source": "cs-compass.quick.shopify.io (live Quick.db)",
    "test_cases": [test2, test3, test4]
}

outpath = os.path.join(script_dir, "additional_test_cases.json")
json.dump(output, open(outpath, 'w'), indent=2, default=str)
