"""Verify that edition scope indexes every original promise without silent omissions."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'docs/PROMISE_MATRIX.json').read_text(encoding='utf-8'))
assert data['claims'] and data['groups']
seen=set()
for source in data['sources']:
    p=root/source['path']
    assert hashlib.sha256(p.read_bytes()).hexdigest()==source['sha256'], 'Promise input changed: review and reconcile '+source['path']
    lines=p.read_text(encoding='utf-8').splitlines();expected=set();in_code=False
    for i,line in enumerate(lines,1):
        if line.startswith('```'):in_code=not in_code;continue
        if in_code or not line.strip() or line.strip()=='---' or line.startswith('#') or line.strip().startswith(('|---','>')):continue
        expected.add(i)
    claims=[c for c in data['claims'] if c['source']==source['path']]
    assert {c['line'] for c in claims}==expected, 'Unindexed original promise'
    for claim in claims:
        assert claim['id'] not in seen;seen.add(claim['id'])
        assert claim['original']==lines[claim['line']-1].strip()
        assert claim['status'] in ('implemented','partial','excluded')
        assert claim['edition_scope'] and (root/claim['test']).is_file()
        if claim['status']!='implemented':assert claim['excluded'], 'Partial scope must name exclusions'
print('PROMISE MATRIX PASS:',len(seen),'original entries, explicit scope and existing test references')
