"""Verify distinct shipped music, original-source hashes and musical finale cues."""
import hashlib,json,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]
folder=root/'assets/audio'
catalog=json.loads((folder/'catalog.json').read_text(encoding='utf-8'))
provenance=json.loads((folder/'music-provenance.json').read_text(encoding='utf-8'))
paths=[entry['path'] for entry in catalog['music'].values()]
assert len(paths)==len(set(paths)), 'Each mood needs its own composition, not aliases'
hashes=[]
for mood,entry in catalog['music'].items():
    raw=(folder/entry['path']).read_bytes();digest=hashlib.sha256(raw).hexdigest();hashes.append(digest)
    assert entry['channels']==2 and entry['seconds']>=100
    assert entry.get('title')
    assert digest==provenance[entry['path']]['wav_sha256']
    assert provenance[entry['path']]['prompt'] and provenance[entry['path']]['source_sha256']
assert len(hashes)==len(set(hashes)), 'Renaming an identical recording does not make distinct music'
for mood in ['victory','defeat']:
    entry=catalog['sfx'][mood]
    assert not entry['loop'] and entry['channels']==2 and 10<=entry['seconds']<=25, mood+' needs a musical stinger'
    assert hashlib.sha256((folder/entry['path']).read_bytes()).hexdigest()==provenance[entry['path']]['wav_sha256']
    assert provenance[entry['path']]['kind']=='stinger'
print('SOUNDTRACK PASS:',len(paths),'unique mood compositions and two musical finales')
