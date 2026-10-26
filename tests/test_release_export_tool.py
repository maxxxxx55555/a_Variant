"""Export preflight must fail closed before touching presets or writing a pack."""
from pathlib import Path
import os,subprocess,sys,tempfile
root=Path(__file__).resolve().parents[1]
tool=root/'tools/export_release.py'
assert tool.exists(),'Environment-only encrypted export tool is required'
before=(root/'export_presets.cfg').read_bytes()
with tempfile.TemporaryDirectory(prefix='export-preflight-') as tmp:
    output=Path(tmp)/'must-not-exist.exe'
    env=os.environ.copy();env.pop('GODOT_SCRIPT_ENCRYPTION_KEY',None)
    result=subprocess.run([sys.executable,str(tool),'--output',str(output)],env=env,capture_output=True,text=True)
    assert result.returncode!=0 and 'GODOT_SCRIPT_ENCRYPTION_KEY' in result.stderr
    assert not output.exists() and (root/'export_presets.cfg').read_bytes()==before
    invalid='invalid-private-key-fixture'
    env['GODOT_SCRIPT_ENCRYPTION_KEY']=invalid
    result=subprocess.run([sys.executable,str(tool),'--output',str(output)],env=env,capture_output=True,text=True)
    assert result.returncode!=0 and invalid not in result.stdout+result.stderr
    assert not output.exists() and (root/'export_presets.cfg').read_bytes()==before
print('RELEASE EXPORT PREFLIGHT PASS: missing/invalid key rejected, no secret output or mutation')
