"""The release archive's document inventory and the contract that keeps it self-consistent.

Kept in the repository, next to the export tooling, because the packaging list is part of
what a release claims to ship: a checkout must be able to verify which documents the archive
must contain without the machine that built it. `tests/test_release_packaging.py` runs the
same contract the packager enforces before it writes an archive.
"""
from pathlib import Path
import hashlib, json, re

ROOT = Path(__file__).resolve().parents[1]
PREFIX = 'MarchlandOaths/'

# Root notices and asset provenance shipped at their repository paths.
NOTICES = [
    'README.md', 'SAVE-INTEGRITY.md',
    'assets/CREDITS.md', 'assets/README.md',
    'assets/art/characters/LICENSE.txt', 'assets/art/humans/Animation-Library-LICENSE.txt',
    'assets/art/humans/Fantasy-Outfits-LICENSE.txt', 'assets/art/humans/Universal-Base-Characters-LICENSE.txt',
    'assets/art/humans/sources.json', 'assets/art/medieval/LICENSE.txt', 'assets/art/realistic/LICENSE.txt',
    'assets/art/realistic/sources.json', 'assets/art/title-provenance.json', 'assets/asset-sources.json',
    'assets/audio/LICENSE.md', 'assets/audio/NOTICES.txt', 'assets/audio/SOUNDTRACK.md',
    'assets/audio/interface-provenance.json', 'assets/audio/music-provenance.json',
    'assets/fonts/GolosText-OFL.txt', 'assets/fonts/Literata-OFL.txt', 'assets/fonts/alegreya-OFL.txt',
    'assets/fonts/manrope-OFL.txt', 'assets/fonts/prata-OFL.txt', 'assets/ui/icon-provenance.json',
    'third_party/Godot/COPYRIGHT.txt', 'third_party/Godot/LICENSE.txt',
]

DOCUMENTS = [
    'docs/ACCEPTANCE_CERTIFICATE.md', 'docs/ANNOUNCE_KIT.md', 'docs/ART_DIRECTION.md',
    'docs/ASSET_REVIEW.json', 'docs/AUDIO_FEEDBACK.md', 'docs/AUDIT_RELOCATION.md',
    'docs/BUG_REGRESSIONS.md', 'docs/CHANGELOG_DRAFT.md', 'docs/CHECKOUT_REPRODUCTION.md',
    'docs/FINAL_REPORT.md', 'docs/GALLERY_ACCEPTANCE_1.6.0.md', 'docs/GALLERY_ACCEPTANCE_1.6.1.md',
    'docs/GALLERY_ACCEPTANCE_1.6.2.md', 'docs/GAME_DESIGN.md',
    'docs/HANDOFF.md', 'docs/JULES_START_PROMPT.txt', 'docs/LOCALIZATION.md', 'docs/LOCALIZATION_AUDIT.md',
    'docs/MECHANICS_MATRIX.json', 'docs/MECHANICS_MATRIX.md', 'docs/PROMISE_MATRIX.json',
    'docs/PROMISE_MATRIX.md', 'docs/RELEASE_1_0.md', 'docs/RELEASE_V2_PLAN.md',
    'docs/RELEASE_1.5.0.md', 'docs/RELEASE_1.5.1.md', 'docs/RELEASE_1.5.2.md', 'docs/RELEASE_1.5.3.md',
    'docs/RELEASE_1.6.0.md', 'docs/RELEASE_1.6.1.md', 'docs/RELEASE_1.6.2.md',
    'docs/OWNER_CHECKS_1.6.0.md', 'docs/OWNER_CHECKS_1.6.1.md',
    'docs/STATIC_AUDIT.md', 'docs/GAME_DESCRIPTION_RU.md',
]

EVIDENCE_ROOTS = ['docs/acceptance', 'docs/acceptance-1.5.2', 'docs/acceptance-1.6.0', 'docs/acceptance-1.6.1',
                  'docs/acceptance-1.6.2', 'docs/galleries', 'docs/press', 'docs/superpowers']

REFERENCE = re.compile(r'[A-Za-z0-9_.\-/]*[A-Za-z0-9_.\-]\.(?:md|json|txt|png|log)')


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tracked_documents() -> list[str]:
    paths = []
    for relative in DOCUMENTS:
        if (ROOT / relative).is_file():
            paths.append(relative)
    for root in EVIDENCE_ROOTS:
        directory = ROOT / root
        if not directory.is_dir():
            continue
        for file in sorted(directory.rglob('*')):
            if file.is_file() and file.suffix.lower() in {'.md', '.json', '.txt', '.log', '.png'}:
                paths.append(file.relative_to(ROOT).as_posix())
    return sorted(set(paths))


def mirrored_licenses() -> list[tuple[str, str]]:
    """The flat licenses/ folder of the published 1.4.0 archive, read from the license contract.

    Every relocation is asserted byte-for-byte by tests/test_license_bytes.py, so the archive
    mirrors the published layout without guessing where a licence came from.
    """
    fixture = json.loads((ROOT / 'tests/fixtures/inherited-license-hashes.json').read_text(encoding='utf-8'))
    pairs = []
    for repository_path, record in fixture['files'].items():
        entry = record['original_zip_entry']
        assert entry.startswith(PREFIX), entry
        pairs.append((repository_path, entry[len(PREFIX):]))
    return sorted(pairs)


def packaging_list() -> dict:
    """Every document and notice the archive must carry, keyed by its entry name."""
    members = {}
    for relative in tracked_documents() + NOTICES:
        path = ROOT / relative
        if not path.is_file():
            raise SystemExit('packaging contract expects a shipped file that is absent: ' + relative)
        members[PREFIX + relative] = path
    for relative, archived in mirrored_licenses():
        path = ROOT / relative
        if not path.is_file():
            raise SystemExit('inherited license contract file is absent: ' + relative)
        if members.get(PREFIX + archived) not in (None, path):
            raise SystemExit('license relocation collides with a shipped path: ' + archived)
        members[PREFIX + archived] = path
    return members


def documentation_index() -> set:
    """Every file under docs/, as repository-relative posix paths, in one walk.

    Resolving each reference against the filesystem instead made the contract take minutes on
    Windows; a single walk keeps it a few seconds as the evidence folders grow.
    """
    return {path.relative_to(ROOT).as_posix() for path in (ROOT / 'docs').rglob('*') if path.is_file()}


def unresolved_references(members: dict, index: set = None) -> list[str]:
    """A shipped document may not point at a repository file that the archive leaves behind.

    The 1.6.1 bundle shipped patch notes whose evidence folder was not in the download; this
    turns that class of mistake into a packaging failure instead of a review finding.
    """
    known = documentation_index() if index is None else index
    unresolved = []
    for name, path in sorted(members.items()):
        if not name.endswith(('.md', '.json', '.txt')):
            continue
        text = path.read_text(encoding='utf-8', errors='replace')
        for token in sorted(set(REFERENCE.findall(text))):
            candidates = [token] if token.startswith('docs/') else ['docs/' + token, token]
            relative = next((candidate for candidate in candidates if candidate in known), None)
            if relative is not None and PREFIX + relative not in members:
                unresolved.append(name + ' -> ' + relative)
    return unresolved


def carries_private_material(members: dict) -> list[str]:
    return sorted(name for name in members
                  if name.endswith('.aes256') or 'export_key' in name or 'credentials' in name)


def audit() -> dict:
    members = packaging_list()
    return {'members': len(members),
            'documents': len(tracked_documents()),
            'notices': len(NOTICES),
            'license_relocations': len(mirrored_licenses()),
            'unresolved_references': unresolved_references(members),
            'private_material': carries_private_material(members)}
