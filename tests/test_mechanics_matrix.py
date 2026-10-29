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
locales='n/a'
if report['coverage_status']=='EXECUTED_PASS':
 # An EXECUTED_PASS claim is only as good as the run that produced it, so the evidence file must
 # exist, report a clean sweep, and still match the bytes of every source it says it executed.
 pointer=report.get('execution_evidence','')
 assert pointer and not pointer.startswith('..'),'EXECUTED_PASS needs a repository-relative evidence path'
 evidence=root/pointer
 assert evidence.is_file(),'EXECUTED_PASS names evidence that is not shipped: '+pointer
 executed=json.loads(evidence.read_text(encoding='utf-8'))
 assert executed.get('failing_references')==[] and executed.get('cells_without_passing_execution')==[],pointer
 assert len(executed.get('display_locales',[]))>=2 and executed.get('references'),pointer
 import hashlib
 for rel,record in executed['references'].items():
  source=root/rel
  assert source.is_file(),rel
  # Both sides hash LF-normalized bytes: the repository stores these sources with LF, while a Windows
  # autocrlf checkout presents CRLF. Content changes still break the digest; line endings alone must not.
  assert hashlib.sha256(source.read_bytes().replace(b'\r\n', b'\n')).hexdigest()==record['source_sha256'],\
   'evidence is stale for '+rel+'; re-run tools/collect_mechanics_evidence.py'
 assert executed['references'].keys()>=refs,pointer
 locales=','.join(executed['display_locales'])
print('MECHANICS MAPPING PASS:',len(report['rows']),'mechanics,',len(report['rows'])*8,'cells;',report['coverage_status'],'in',locales)
