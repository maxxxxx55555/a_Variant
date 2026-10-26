"""The compiled trust root must reject changed data and self-signed replacement manifests."""
import hashlib,json,subprocess,sys,tempfile,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[1]
tool=root/'tools/build_manifest.py'
assert tool.is_file(),'Missing critical-data manifest generator'
attributes=root/'.gitattributes'
assert attributes.is_file(),'Windows checkout must preserve manifest source bytes'
policy=attributes.read_text()
for rule in ['data/**/*.json text eol=lf','assets/audio/catalog.json text eol=lf','scripts/security/TrustedData.gd text eol=lf']:
    assert rule in policy,'Missing deterministic checkout rule: '+rule
subprocess.run([sys.executable,str(tool),'--check'],check=True)
manifest=root/'data/critical-manifest.json'
source=root/'scripts/security/TrustedData.gd'
before=(manifest.read_bytes(),source.read_bytes())
subprocess.run([sys.executable,str(tool)],check=True)
assert before==(manifest.read_bytes(),source.read_bytes()),'Generation is not byte stable'
entries=json.loads(manifest.read_text())['files']
expected={'res://'+p.relative_to(root).as_posix() for p in (root/'data').rglob('*.json') if p!=manifest}|{'res://assets/audio/catalog.json'}
assert set(entries)==expected,'Critical JSON inventory incomplete'
assert all(hashlib.sha256((root/p[6:]).read_bytes()).hexdigest()==v for p,v in entries.items())
with tempfile.TemporaryDirectory() as folder:
    fixture=Path(folder)
    for rel in ['data','scripts/security','tools']:(fixture/rel).mkdir(parents=True,exist_ok=True)
    shutil.copy2(tool,fixture/'tools/build_manifest.py')
    shutil.copy2(source,fixture/'scripts/security/TrustedData.gd')
    for path in entries:
        target=fixture/path[6:];target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/path[6:],target)
    shutil.copy2(manifest,fixture/'data/critical-manifest.json')
    changed=fixture/next(iter(entries))[6:];changed.write_bytes(changed.read_bytes()+b' ')
    check=subprocess.run([sys.executable,str(fixture/'tools/build_manifest.py'),'--check'],capture_output=True)
    assert check.returncode!=0,'Modified critical data passed export preflight'
    fake=json.loads((fixture/'data/critical-manifest.json').read_text())
    fake['files']['res://'+changed.relative_to(fixture).as_posix()]=hashlib.sha256(changed.read_bytes()).hexdigest()
    (fixture/'data/critical-manifest.json').write_text(json.dumps(fake))
    check=subprocess.run([sys.executable,str(fixture/'tools/build_manifest.py'),'--check'],capture_output=True)
    assert check.returncode!=0,'Self-updated manifest bypassed compiled trust root'
print('CRITICAL MANIFEST PASS:',len(entries),'files, stable generation, tamper and replacement rejection')
