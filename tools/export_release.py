"""Build an encrypted public/private Windows pack; never publishes or stores keys."""
import argparse,hashlib,json,os,re,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--qa',action='store_true',help='Private verifier pack, excluded from public release assets')
    parser.add_argument('--pack',action='store_true',help='Export a standalone encrypted PCK')
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--template',type=Path,default=os.environ.get('GODOT_WINDOWS_RELEASE_TEMPLATE'))
    options=parser.parse_args()
    encryption_key=os.environ.get('GODOT_SCRIPT_ENCRYPTION_KEY','')
    if not re.fullmatch(r'[0-9a-fA-F]{64}',encryption_key):
        parser.error('GODOT_SCRIPT_ENCRYPTION_KEY must supply a private256-bit hexadecimal key')
    if not options.godot:parser.error('Pass --godot or set GODOT_BIN')
    if not options.template or not options.template.is_file():
        parser.error('Pass --template or GODOT_WINDOWS_RELEASE_TEMPLATE with the matching custom release template')
    template=options.template.resolve()
    with template.open('rb') as stream:
        if stream.read(2)!=b'MZ' or template.stat().st_size<1000000:parser.error('Custom template must be a real Windows release executable')
    target=options.output.resolve()
    if target.suffix.lower()!=('.pck' if options.pack else '.exe'):parser.error('Output extension must match --pack/.pck or native .exe')
    if target.exists():parser.error('Refusing to overwrite an existing artifact; choose a fresh staging path')
    manifest_tool=ROOT/'tools/build_manifest.py'
    if not manifest_tool.is_file():parser.error('Critical-data manifest generator is required')
    if manifest_tool.is_file():
        result=subprocess.run([sys.executable,str(manifest_tool),'--check'],cwd=ROOT,capture_output=True,text=True)
        if result.returncode:parser.error('Critical-data manifest is stale; regenerate and review before export')
    target.parent.mkdir(parents=True,exist_ok=True)
    cache=ROOT/'.godot';cache.mkdir(exist_ok=True)
    lock=cache/'release-export.lock'
    try:lock_file=lock.open('x')
    except FileExistsError:parser.error('Another export holds this project lock')
    preset_path=ROOT/'export_presets.cfg'
    original=preset_path.read_bytes()
    original_credentials=None
    credentials=cache/'export_credentials.cfg'
    if credentials.exists():original_credentials=credentials.read_bytes()
    logs=[]
    try:
        text=original.decode('utf-8')
        replacement='custom_template/release='+json.dumps(str(template).replace('\\','/'))
        text,count=re.subn(r'^custom_template/release=.*$',lambda _:replacement,text,flags=re.M)
        if count<2:raise RuntimeError('Both separate Windows presets must configure a custom template')
        preset_path.write_text(text,encoding='utf-8')
        env={key:value for key,value in os.environ.items() if key=='GODOT_SCRIPT_ENCRYPTION_KEY' or not re.search(r'TOKEN|PASSWORD|SECRET|API_KEY',key,re.I)};env['GAME_AUDIO_MUTED']='1'
        preset='Windows QA' if options.qa else 'Windows Desktop'
        steps=[['--headless','--editor','--import','--quit'],['--headless','--export-pack' if options.pack else '--export-release',preset,str(target)]]
        for switches in steps:
            result=subprocess.run([options.godot,'--path',str(ROOT),*switches],cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=900)
            sanitized=result.stdout.replace(encryption_key,'<redacted>')
            logs.append(sanitized)
            if result.returncode or 'SCRIPT ERROR' in sanitized:raise RuntimeError('Godot export failed; inspect the sanitized log')
        if not target.is_file() or target.stat().st_size<10000:raise RuntimeError('No complete export artifact was produced')
        report={'preset':preset,'private_qa':options.qa,'encrypted':True,'directory_encrypted':True,'template_sha256':hashlib.sha256(template.read_bytes()).hexdigest(),'artifact_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'artifact_bytes':target.stat().st_size,'key_storage':'environment only; no key recorded','source_preset_restored':True}
        target.with_suffix(target.suffix+'.export.json').write_text(json.dumps(report,indent=2)+'\n')
        print('ENCRYPTED EXPORT COMPLETE:',target.name,preset)
        return 0
    except (RuntimeError,subprocess.TimeoutExpired) as error:
        print(str(error).replace(encryption_key,'<redacted>'),file=sys.stderr)
        return 1
    finally:
        preset_path.write_bytes(original)
        if original_credentials is None:
            if credentials.exists():credentials.unlink()
        else:credentials.write_bytes(original_credentials)
        target.with_suffix(target.suffix+'.export.log').write_text('\n'.join(logs),encoding='utf-8')
        lock_file.close();lock.unlink()

if __name__=='__main__':raise SystemExit(main())
