"""Reject staged cross-project content and credential values; never delete files.

Shared tooling by design: the guard knows both project identities to enforce the boundary.
"""
from pathlib import Path
import argparse, re, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
PROFILE='a_Variant' if 'Marchland Oaths' in (ROOT/'project.godot').read_text(encoding='utf-8') else 'game_for_day'
EXCEPTIONS={
 'tools/check_repo_isolation.py':'shared tooling by design: boundary definitions for both projects',
 'tests/test_repo_isolation.py':'shared tooling by design: deliberately invalid negative fixtures',
 'tools/generate_audio.py':'shared tooling by design: explicit independent audio profiles',
 'tools/fetch_gemini_music.py':'shared tooling by design: reusable secret-free API client',
 'tests/test_audio.gd':'shared tooling by design: runtime API verification',
}
FOREIGN={
 'a_Variant':re.compile(r'Heirs[ _]?of[ _]?Fortune|HeirsOfFortune|Forbes|ForbesLadder|\bdynasty\b|\bFortune\b|["\x27](?:welcome|study|career|tycoon)["\x27]\s*:',re.I),
 'game_for_day':re.compile(r'Marchland|Oaths of the March|Клятвы Пограничья|march\.tscn|["\x27](?:exploration|settlement|combat|war)["\x27]\s*:|\b(?:siege|faction)\b',re.I)
}
SECRETS=[re.compile(r'AIza[0-9A-Za-z_-]{30,}'),re.compile(r'gh[pousr]_[0-9A-Za-z]{20,}'),
 re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
 re.compile(r'(?i)(?:api[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*["\x27][A-Za-z0-9_/-]{20,}["\x27]')]
def inspect_text(path,text):
    errors=[]
    if any(p.search(text) for p in SECRETS): errors.append(path+': credential material detected')
    # Third-party notices retain their authors' original bytes and names.
    shared=path in EXCEPTIONS or path.startswith('third_party/Godot/')
    if not shared and FOREIGN[PROFILE].search(text): errors.append(path+': foreign project marker detected')
    return errors
def run_git(*args):
    exe=shutil.which('git')
    if not exe: raise RuntimeError('Git must be available on PATH')
    base=[exe,'-C',str(ROOT)]
    origin=subprocess.check_output(base+['remote','get-url','origin'],text=True).strip().removesuffix('.git').rstrip('/')
    if not origin.endswith('/maxxxxx55555/'+PROFILE): raise RuntimeError('Unexpected origin: '+origin)
    return subprocess.check_output(base+list(args))
def scan(staged=True):
    paths=run_git('diff','--cached','--name-only','--diff-filter=ACMR','-z') if staged else run_git('ls-files','-z')
    errors=[]
    for raw in paths.split(b'\0'):
        if not raw: continue
        path=raw.decode('utf-8')
        if path.startswith(('.godot/','builds/')): errors.append(path+': generated build/cache must not be committed')
        content=run_git('show',':'+path) if staged else (ROOT/path).read_bytes()
        if b'\0' in content[:8192]: continue
        try: text=content.decode('utf-8')
        except UnicodeDecodeError: continue
        errors+=inspect_text(path,text)
    return errors
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--tree',action='store_true');args=parser.parse_args()
    errors=scan(not args.tree)
    for error in errors: print(error)
    print('REPO ISOLATION '+('FAIL' if errors else 'PASS')+': '+PROFILE)
    sys.exit(bool(errors))
