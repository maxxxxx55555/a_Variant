"""Keep every edition mechanic mapped to executable coverage before accepting a release."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
report=json.loads((root/'docs/MECHANICS_MATRIX.json').read_text(encoding='utf-8'))
columns=['happy','bounds','rapid_input','pause_background','save_load_hash','en_ru','audio','ui_escape']
assert report['schema']==1 and report['columns']==columns
assert report['coverage_status'] in ['MAPPED_EXECUTION_PENDING','EXECUTED_PASS']
assert report['rows'] and len({r['mechanic'] for r in report['rows']})==len(report['rows'])
refs=set()
for row in report['rows']:
 assert row['mechanic'].strip() and set(row['cells'])==set(columns)
 for column in columns:
  assert row['cells'][column],(row['mechanic'],column)
  for ref in row['cells'][column]:
   rel=ref['path'];assert rel.startswith('tests/') and '..' not in Path(rel).parts
   path=root/rel;assert path.is_file(),rel
   text=path.read_text(encoding='utf-8')
   assert any(marker in text for marker in ['check(', 'assert(', 'fail(', 'FAIL:']),rel
   assert ref['scope'].strip();refs.add(rel)
doc=(root/'docs/MECHANICS_MATRIX.md').read_text(encoding='utf-8')
for rel in refs:assert '../'+rel in doc,rel
assert 'Publication remains locked' in doc or report['coverage_status']=='EXECUTED_PASS'
print('MECHANICS MAPPING PASS:',len(report['rows']),'mechanics,',len(report['rows'])*8,'cells;',report['coverage_status'])
