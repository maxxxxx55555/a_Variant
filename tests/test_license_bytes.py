"""Keep the inherited published license bytes, including their original line endings."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
record=json.loads((root/'tests/fixtures/inherited-license-hashes.json').read_text(encoding='utf-8'))
failures=[path for path,item in record['files'].items() if hashlib.sha256((root/path).read_bytes()).hexdigest()!=item['sha256']]
for path in failures:print('LICENSE BYTES MISMATCH:',path)
assert not failures, 'Inherited published licenses changed: '+', '.join(failures)
print('INHERITED LICENSE BYTE CONTRACT PASS:',len(record['files']),'files from published1.4.0')
