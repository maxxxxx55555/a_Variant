"""Machine-generated static census for the shipping gate: sidecars, assets, markers, dead code.

Run from the repository root. The census is a review aid: every non-zero line prints the
offending paths so a human can delete, wire up, or justify them in docs/STATIC_AUDIT.md.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {'.gd', '.tscn', '.tres', '.csv', '.json', '.godot', '.cfg', '.md', '.py', '.yml'}
ASSET_FOLDERS = ('assets', 'scenes', 'data')
# Bracketed so this rule does not match the pattern that declares it.
MARKERS = re.compile(r'\b([T]ODO|[F]IXME|[X]{3}|[H]ACK|LOREM\s+IPSUM)\b')
ENGINE_VIRTUAL = re.compile(r'^_(ready|process|physics_process|enter_tree|exit_tree|initialize|'
                           r'toast|input|unhandled_input|input_event|draw|setup|notification|'
                           r'get_configuration_warnings|validate|save|load|duplicate)\w*$')
FUNCTION = re.compile(r'^(?:@\w+\s+)*(static\s+)?func\s+(\*?\w+)\s*\(', re.M)


def tracked() -> list[str]:
    result = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, capture_output=True)
    # git lists the index, so a file deleted before staging still appears here. Counting it would both
    # crash the corpus read and publish an inventory number the shipped tree cannot match.
    return sorted(path for path in result.stdout.decode().split('\0') if path and (ROOT / path).exists())


def corpus(files: list[str]) -> str:
    chunks = []
    for relative in files:
        path = ROOT / relative
        if path.suffix in TEXT_SUFFIXES and path.stat().st_size < 4_000_000:
            chunks.append(path.read_text(encoding='utf-8', errors='replace'))
    return '\n'.join(chunks)


def gltf_dependencies(path: Path) -> set[str]:
    found = set()
    try:
        document = json.loads(path.read_text(encoding='utf-8', errors='replace'))
    except (json.JSONDecodeError, UnicodeDecodeError):
        return found
    for key in ('buffers', 'images'):
        for entry in document.get(key, []):
            uri = entry.get('uri')
            if isinstance(uri, str) and not uri.startswith('data:'):
                found.add((path.parent / uri).resolve().as_posix())
    return found


def main() -> int:
    files = tracked()
    text = corpus(files)
    problems = 0

    sidecars = []
    for relative in files:
        path = ROOT / relative
        if path.suffix == '.uid':
            if not path.with_suffix('').exists():
                sidecars.append(relative)
        elif relative.endswith('.import'):
            stem = re.sub(r'\.import$', '', relative)
            if not (ROOT / stem).exists():
                sidecars.append(relative)
    print('ORPHAN SIDECARS:', len(sidecars), sidecars[:10])
    problems += len(sidecars)

    referenced = set()
    for relative in files:
        if not relative.endswith(('.gltf', '.glb')):
            continue
        for dependency in gltf_dependencies(ROOT / relative):
            referenced.add(dependency)
    unreferenced_assets = []
    for relative in files:
        path = ROOT / relative
        if not any(relative.startswith(folder + '/') for folder in ASSET_FOLDERS):
            continue
        if path.suffix in {'.uid', '.import', '.md', '.txt', '.py'}:
            continue
        if path.suffix in {'.gltf', '.glb'} and path.resolve().as_posix() in referenced:
            continue
        if path.name in text or relative in text:
            continue
        # IconSet.NAMES and data-driven lookups compose a folder plus a bare name.
        if path.stem in text:
            continue
        unreferenced_assets.append(relative)
    print('UNREFERENCED SOURCES:', len(unreferenced_assets), unreferenced_assets[:12])
    problems += len(unreferenced_assets)

    marked = []
    for relative in files:
        path = ROOT / relative
        if not (relative.startswith(('scripts/', 'tests/', 'tools/', 'data/', 'scenes/'))):
            continue
        if path.suffix not in TEXT_SUFFIXES:
            continue
        for number, line in enumerate(path.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
            if MARKERS.search(line):
                marked.append(relative + ':' + str(number))
    print('DEVELOPMENT MARKERS:', len(marked), marked[:10])
    problems += len(marked)

    dead = []
    for relative in files:
        if not relative.startswith('scripts/') or not relative.endswith('.gd'):
            continue
        body = (ROOT / relative).read_text(encoding='utf-8', errors='replace')
        for _, name in FUNCTION.findall(body):
            clean = name.lstrip('*')
            if ENGINE_VIRTUAL.match(clean) or clean in {'new', '_init'}:
                continue
            elsewhere = text.count(clean) - body.count(clean)
            if elsewhere <= 0 and body.count(clean) <= 1:
                dead.append(relative + '::' + clean)
    print('UNREFERENCED SHIPPING FUNCTIONS:', len(dead), dead[:12])
    problems += len(dead)

    scripts = [relative for relative in files if relative.startswith('scripts/') and relative.endswith('.gd')]
    tests = [relative for relative in files if relative.startswith('tests/') and relative.endswith('.gd')]
    print('INVENTORY: shipping scripts=' + str(len(scripts)) + ' test scripts=' + str(len(tests)))
    print('STATIC CENSUS: ' + ('PASS' if problems == 0 else 'REVIEW ' + str(problems) + ' items'))
    return 0 if problems == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
