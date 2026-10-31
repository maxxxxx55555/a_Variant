"""The release archive's document inventory must be self-consistent and reproducible from a checkout."""
import sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'tools'))
import release_packaging as packaging

members = packaging.packaging_list()
assert len(members) > 900, 'the packaging list collapsed: ' + str(len(members))
for required in ['docs/RELEASE_1.6.2.md', 'docs/GALLERY_ACCEPTANCE_1.6.2.md', 'docs/HANDOFF.md',
                 'SAVE-INTEGRITY.md', 'README.md']:
    assert packaging.PREFIX + required in members, required + ' must ship with the archive'
edition_evidence = [name for name in members if '/docs/acceptance-1.6.2/' in name]
assert edition_evidence, 'the current edition evidence folder must ship inside the archive'
assert not any('1.6.1' in name and '/docs/acceptance-1.6.1/' in name for name in edition_evidence)

unresolved = packaging.unresolved_references(members)
assert not unresolved, 'shipped documents point at files the archive leaves out: ' + str(unresolved[:5])
assert not packaging.carries_private_material(members), 'private material reached the packaging list'

# The reference contract must be able to fail, or it proves nothing.
probe = dict(members)
victim = packaging.PREFIX + 'docs/GALLERY_ACCEPTANCE_1.6.1.md'
assert victim in probe, 'the gallery acceptance notes of 1.6.1 must be listed'
del probe[victim]
fired = packaging.unresolved_references(probe)
assert any(victim[len(packaging.PREFIX):] in line for line in fired), \
    'removing a referenced document must be reported, got: ' + str(fired[:3])
print('RELEASE PACKAGING CONTRACT PASS: %d members, %d documents, %d evidence entries, reference oracle fires'
      % (len(members), len(packaging.tracked_documents()), len(edition_evidence)))
