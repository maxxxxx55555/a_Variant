"""Real Git checkouts must preserve trusted source bytes under either EOL default."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
GIT = shutil.which('git')


def git(root, *args, input=None):
    assert GIT, 'Git is required to verify real checkout byte portability'
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith('GIT_')}
    environment.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
                       GIT_ATTR_NOSYSTEM='1', GIT_TERMINAL_PROMPT='0')
    result = subprocess.run(
        [GIT, '-c', 'safe.directory=' + str(root), '-c', 'core.attributesFile=' + os.devnull,
         '-C', str(root), *args], input=input, capture_output=True, env=environment)
    assert result.returncode == 0, result.stderr.decode('utf-8', errors='replace')
    return result.stdout



def verify_git_environment_isolation(base):
    """Ambient Git redirects may target only a disposable sentinel during this test."""
    sentinel = base / 'redirect-sentinel'
    intended = base / 'intended-repository'
    sentinel.mkdir()
    intended.mkdir()
    bootstrap_environment = {key: value for key, value in os.environ.items()
                             if not key.startswith('GIT_')}
    bootstrap_environment.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
                                 GIT_ATTR_NOSYSTEM='1', GIT_TERMINAL_PROMPT='0')
    for arguments in [('init', '--quiet'), ('add', '--all')]:
        if arguments[0] == 'add':
            (sentinel / 'sentinel.txt').write_text('Sentinel contents must remain unchanged.\n', encoding='utf-8')
        result = subprocess.run([GIT, '-c', 'safe.directory=' + str(sentinel),
                                 '-C', str(sentinel), *arguments],
                                env=bootstrap_environment, capture_output=True)
        assert result.returncode == 0, 'Cannot initialize disposable redirect sentinel'
    before = {p.relative_to(sentinel).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sentinel.rglob('*') if p.is_file()}
    redirects = {
        'GIT_DIR': str(sentinel / '.git'),
        'GIT_COMMON_DIR': str(sentinel / '.git'),
        'GIT_WORK_TREE': str(sentinel),
        'GIT_INDEX_FILE': str(sentinel / '.git/index'),
        'GIT_OBJECT_DIRECTORY': str(sentinel / '.git/objects'),
        'GIT_ALTERNATE_OBJECT_DIRECTORIES': str(sentinel / '.git/objects'),
    }
    previous = {key: os.environ.get(key) for key in redirects}
    try:
        os.environ.update(redirects)
        git(intended, 'init', '--quiet')
        assert (intended / '.git').is_dir(), 'Ambient Git redirect changed the intended repository target'
        (intended / 'intended.txt').write_text('Stage only this disposable working file.\n', encoding='utf-8')
        git(intended, 'add', '--all')
        assert git(intended, 'ls-files', '-z') == b'intended.txt\0', 'Ambient Git redirect changed the intended index'
    finally:
        for key, value in previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
    after = {p.relative_to(sentinel).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
             for p in sentinel.rglob('*') if p.is_file()}
    assert before == after, 'Ambient Git redirect changed sentinel metadata or index bytes'
    print('GIT ENVIRONMENT PASS: redirected directory/worktree/index/object store ignored; sentinel unchanged')


def assert_effective_lf(root):
    """Inspect effective attributes, including local overrides, not policy prose."""
    manifest = json.loads((root / 'data/critical-manifest.json').read_bytes())
    paths = [p.removeprefix('res://') for p in manifest['files']]
    paths += ['data/critical-manifest.json', 'scripts/security/TrustedData.gd',
              'tools/generate_audio.py']
    raw = git(root, 'check-attr', '-z', '--stdin', 'text', 'eol',
              input=b'\0'.join(p.encode() for p in paths) + b'\0')
    fields = raw.decode().split('\0')[:-1]
    actual = {(fields[i], fields[i + 1]): fields[i + 2]
              for i in range(0, len(fields), 3)}
    for path in paths:
        assert actual.get((path, 'text')) == 'set', 'Missing effective text attribute: ' + path
        assert actual.get((path, 'eol')) == 'lf', 'Nonportable effective eol attribute: ' + path


def snapshot_files(root):
    selected = [root / '.gitattributes']
    for folder, suffixes in [('data', {'.json', '.csv'}), ('scripts', {'.gd'}),
                             ('scenes', {'.tscn'}), ('assets/audio', {'.wav', '.json'})]:
        selected += [p for p in (root / folder).rglob('*')
                     if p.is_file() and p.suffix in suffixes]
    selected += [root / p for p in [
        'tools/build_manifest.py', 'tools/generate_audio.py',
        'tests/test_critical_manifest.py', 'tests/test_copy_contract.py',
        'tests/test_audio_assets.py', 'tests/test_checkout_bytes.py']]
    return sorted(set(selected))


def verify():
    failures = []
    with tempfile.TemporaryDirectory(prefix='marchland-checkout-bytes-') as temporary:
        temporary = Path(temporary)
        verify_git_environment_isolation(temporary)
        seed = temporary / 'seed'
        seed.mkdir()
        git(seed, 'init', '--quiet')
        git(seed, 'config', 'core.autocrlf', 'false')
        for path in snapshot_files(ROOT):
            relative = path.relative_to(ROOT)
            assert path.is_file() and not path.is_symlink(), 'Unsafe snapshot input: ' + str(relative)
            destination = seed / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, destination)
        git(seed, 'add', '--all')
        tree = git(seed, 'write-tree').decode().strip()
        commit = git(seed, '-c', 'user.name=Checkout regression',
                     '-c', 'user.email=checkout-test@localhost',
                     'commit-tree', tree, '-m', 'Disposable canonical source snapshot').decode().strip()
        git(seed, 'update-ref', 'refs/heads/checkout-test', commit)
        for mode in ['false', 'true']:
            checkout = temporary / ('autocrlf-' + mode)
            checkout.mkdir()
            git(checkout, 'init', '--quiet')
            # Copy only disposable Git objects; materialization is a real plain checkout.
            # Avoid transport helpers and never share source working-file hardlinks.
            shutil.copytree(seed / '.git/objects', checkout / '.git/objects', dirs_exist_ok=True)
            git(checkout, 'config', 'core.autocrlf', mode)
            assert not (checkout / '.git/info/attributes').exists(), 'A plain checkout must have no local attribute overrides'
            git(checkout, 'checkout', '--quiet', '--force', '--detach', commit)
            assert_effective_lf(checkout)
            manifest = json.loads((checkout / 'data/critical-manifest.json').read_bytes())
            for path, expected in manifest['files'].items():
                actual = hashlib.sha256((checkout / path[6:]).read_bytes()).hexdigest()
                if actual != expected:
                    failures.append(f'core.autocrlf={mode}: critical bytes mismatch: {path}')
            for script in ['tools/build_manifest.py', 'tests/test_copy_contract.py',
                           'tests/test_audio_assets.py', 'tests/test_critical_manifest.py']:
                command = [sys.executable, str(checkout / script)]
                if script == 'tools/build_manifest.py':
                    command.append('--check')
                result = subprocess.run(command, capture_output=True, text=True,
                                        encoding='utf-8', errors='replace', timeout=90)
                print(f'core.autocrlf={mode} {script}: ' + ('PASS' if result.returncode == 0 else 'FAIL'))
                print(result.stdout, end='')
                if result.returncode:
                    print(result.stderr, end='')
                    failures.append(f'core.autocrlf={mode}: {script}')
            assert not git(checkout, 'diff', '--name-only'), 'Contract checks changed canonical source'
            # A local override must not masquerade as the portable committed policy.
            override = checkout / '.git/info/attributes'
            override.write_text('assets/audio/catalog.json text eol=crlf\n', encoding='utf-8')
            try:
                assert_effective_lf(checkout)
            except AssertionError as error:
                assert 'Nonportable effective eol attribute' in str(error)
            else:
                raise AssertionError('Local CRLF override bypassed effective-attribute verification')
    assert not failures, 'Plain fresh-checkout byte contract failed:\n' + '\n'.join(failures)
    print('CHECKOUT BYTES PASS: plain Git LF/CRLF defaults, effective attributes, manifest/copy/audio and tamper contracts')


if __name__ == '__main__':
    verify()
