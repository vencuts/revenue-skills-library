#!/usr/bin/env python3
"""Build test dataset from real CS Compass Quick.db data."""
import json
import sys
from datetime import datetime

# Parse mitigations
mitigations = []
raw = open('/tmp/eval-mitigations-raw.json').read()
for line in raw.split('\n'):
    line = line.strip()
    if line.startswith('{') and 'result' in line:
        d = json.loads(line)
        text = d.get('result', {}).get('content', [{}])[0].get('text', '')
        if text:
            mitigations = json.loads(text)
        break

# Parse RHS scores
rhs_scores = {}
raw = open('/tmp/eval-rhs-raw.json').read()
for line in raw.split('\n'):
    line = line.strip()
    if line.startswith('{') and 'result' in line:
        d = json.loads(line)
        text = d.get('result', {}).get('content', [{}])[0].get('text', '')
        if text:
            data = json.loads(text)
            if data:
                rhs_scores = data[0].get('scores', {})
        break

# Parse risk overrides
overrides = []
raw = open('/tmp/eval-risk-overrides.json').read()
for line in raw.split('\n'):
    line = line.strip()
    if line.startswith('{') and 'result' in line:
        d = json.loads(line)
        text = d.get('result', {}).get('content', [{}])[0].get('text', '')
        if text:
            overrides = json.loads(text)
        break

# Build test accounts
test_accounts = []
seen_ids = set()
for m in mitigations:
    aid = m.get('account_id')
    if not aid or aid in seen_ids:
        continue
    seen_ids.add(aid)
    rhs = rhs_scores.get(aid, {})
    test_accounts.append({
        'account_id': aid,
        'account_name': m.get('account_name'),
        'csm_name': m.get('csm_name'),
        'csm_email': m.get('csm_email'),
        'lead_name': m.get('lead_name'),
        'segment': m.get('segment'),
        'gmv': m.get('gmv_at_start'),
        'revenue': m.get('revenue_at_start'),
        'risk_category': m.get('initial_risk_category'),
        'risk_score': m.get('initial_risk_score'),
        'sf_risk_level': m.get('initial_sf_risk_level'),
        'risk_flags': m.get('risk_flags_at_start', []),
        'mitigation_status': m.get('status'),
        'rhs_score': rhs.get('s'),
        'rhs_tier': rhs.get('t'),
        'rhs_engagement': rhs.get('e'),
    })

test_data = {
    'generated_at': datetime.now().isoformat(),
    'source': 'cs-compass.quick.shopify.io (live Quick.db)',
    'total_rhs_accounts': len(rhs_scores),
    'total_mitigation_accounts': len(test_accounts),
    'total_risk_overrides': len(overrides),
    'rhs_distribution': {
        'healthy': sum(1 for v in rhs_scores.values() if v.get('t') == 'Healthy'),
        'atrophying': sum(1 for v in rhs_scores.values() if v.get('t') == 'Atrophying'),
        'at_risk': sum(1 for v in rhs_scores.values() if v.get('t') == 'At Risk'),
    },
    'test_accounts': test_accounts,
    'risk_overrides': [{
        'account_id': o.get('account_id'),
        'account_name': o.get('account_name'),
        'override_category': o.get('override_risk_category'),
        'flags_addressed': o.get('flags_addressed', []),
        'status': o.get('status'),
    } for o in overrides],
}

json.dump(test_data, sys.stdout, indent=2, default=str)
