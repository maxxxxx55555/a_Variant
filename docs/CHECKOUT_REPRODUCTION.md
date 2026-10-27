# Marchland Oaths: diagnostic checkout reproduction

**DIAGNOSTIC ONLY — NOT_ACCEPTED. Announcement hold remains in effect.**
This document records a controlled reproduction experiment, not a fix, acceptance sign-off, or permission to announce. The negative [acceptance certificate](ACCEPTANCE_CERTIFICATE.md) remains authoritative.

## Frozen identity and default failure

- Repository: https://github.com/maxxxxx55555/a_Variant
- Tag: `v1.5.1`
- Commit: `006c164895d8d70fc2a72a61610b2ad27bb9e97e`
- Source tree: `2ddab3608b569c15c373406b440b8a78baec9c5f`

The ordinary fresh tag checkout still fails the mandatory source gate: 7 critical JSON files do not match the committed integrity digests; the interface-audio generator digest also differs. Integrity safe mode and failed export preflight remain recorded baseline failures. No result below replaces those failures or validates the published executable by inference.

## Exact diagnostic profile

Install these rules in the **disposable clone's** `.git/info/attributes`, which has higher precedence than the tagged `.gitattributes`:

```gitattributes
# Diagnostic checkout serialization only; immutable blobs and contracts unchanged.
assets/audio/catalog.json text eol=crlf
data/balance/alchemy.json text eol=crlf
data/balance/buildings.json text eol=crlf
data/balance/campaign.json text eol=crlf
data/balance/crafting.json text eol=crlf
data/balance/equipment.json text eol=crlf
data/balance/localization.json text eol=crlf
tools/generate_audio.py text eol=crlf
```

The listed JSON and generator files require CRLF working bytes for this experiment. The committed manifest and `TrustedData.gd` must retain their exact LF bytes; the profile does not override them. Do not regenerate the manifest to accept altered data, rewrite its trust root, change protected fixtures, alter provenance/legal files, or apply a blanket text/JSON/Python conversion. All tagged files remain logically and canonically unchanged; the selected scratch working files deliberately have different raw bytes.

## Portable reproduction commands

Requires Git and Python 3. Save the following as a temporary Python file outside any game checkout and run it from a scratch parent directory. It creates a new scratch clone and reserializes selected working files through untracked local Git metadata; it must never target the original working repository. The commands print both raw SHA256 values and compare Git's canonical, clean-filtered blob identity.

```python
from pathlib import Path
import hashlib
import subprocess

root = Path('marchland-checkout-diagnostic')
assert not root.exists(), "Use a new disposable directory"
subprocess.run(["git", "clone", "--no-checkout", "--single-branch",
                "--branch", 'v1.5.1',
                "https://github.com/maxxxxx55555/a_Variant", str(root)], check=True)

def git(*args):
    return subprocess.check_output(["git", "-C", str(root), *args])

assert git("rev-parse", "v1.5.1^{commit}").decode().strip() == '006c164895d8d70fc2a72a61610b2ad27bb9e97e'
assert git("rev-parse", "v1.5.1^{tree}").decode().strip() == '2ddab3608b569c15c373406b440b8a78baec9c5f'
git("config", "core.autocrlf", "true")  # Match the audited Windows baseline.
attribute_path = Path(git("rev-parse", "--git-path", "info/attributes").decode().strip())
if not attribute_path.is_absolute():
    attribute_path = root / attribute_path
assert not attribute_path.exists(), "Do not overwrite an existing local profile"
attribute_path.parent.mkdir(parents=True, exist_ok=True)
rules = ['# Diagnostic checkout serialization only; immutable blobs and contracts unchanged.', 'assets/audio/catalog.json text eol=crlf', 'data/balance/alchemy.json text eol=crlf', 'data/balance/buildings.json text eol=crlf', 'data/balance/campaign.json text eol=crlf', 'data/balance/crafting.json text eol=crlf', 'data/balance/equipment.json text eol=crlf', 'data/balance/localization.json text eol=crlf', 'tools/generate_audio.py text eol=crlf']
attribute_path.write_bytes(("\n".join(rules) + "\n").encode("utf-8"))
git("checkout", "--detach", 'v1.5.1')

for path in ['assets/audio/catalog.json', 'data/balance/alchemy.json', 'data/balance/buildings.json', 'data/balance/campaign.json', 'data/balance/crafting.json', 'data/balance/equipment.json', 'data/balance/localization.json', 'tools/generate_audio.py']:
    tagged = git("show", "v1.5.1:" + path)
    working = (root / path).read_bytes()
    expected_blob = git("rev-parse", "v1.5.1:" + path).decode().strip()
    cleaned_blob = git("hash-object", "--path=" + path, path).decode().strip()
    assert expected_blob == cleaned_blob
    assert tagged.replace(b"\r\n", b"\n") == working.replace(b"\r\n", b"\n")
    print(path, "tag SHA256=" + hashlib.sha256(tagged).hexdigest(),
          "working SHA256=" + hashlib.sha256(working).hexdigest(),
          "canonical Git blob=" + cleaned_blob)

for path in ["data/critical-manifest.json", "scripts/security/TrustedData.gd"]:
    assert (root / path).read_bytes() == git("show", "v1.5.1:" + path)
git("diff", "--exit-code", 'v1.5.1', "--")
```

A clean Git diff proves canonical blob equality under the active filters; it does **not** prove identical raw working-file bytes. `.git/info/attributes` is untracked Git metadata, but the checkout performed through it reserializes actual scratch game files. This distinction is essential under the current freeze.

## Observed evidence and limits

Focused profile-assisted checks in the separate owned diagnostic checkout:

- `tools/build_manifest.py --check`: **PASS** (exit 0).
- `tests/test_critical_manifest.py`: **PASS** (exit 0).
- `tests/test_audio_assets.py`: **PASS** (exit 0).
- `tests/test_copy_contract.py`: **PASS** (exit 0).
- `tests/test_soundtrack.py`: **PASS** (exit 0).

The critical-manifest check includes stable regeneration plus tamper/replacement rejection. Canonical hashes equal the tagged blobs and the canonical diff is empty; raw before/after hashes are recorded separately. These results show a serialization mismatch, not that the tagged checkout policy is correct.

Full rendered EN/RU suites completed under this diagnostic profile; **these passes do not satisfy the default-checkout gate**.

| Locale | Result | Godot cases | Seconds | Console SHA256 |
|---|---|---|---|---|
| EN | PASS | 62 | 584.171 | `6c434598ed70c5f057593bfe6c0d98540285b5bbd9e66c9903da0630a9f64d09` |
| RU | PASS | 62 | 457.156 | `d3ecce8095c0a9d153351c986a577ed5fb4de0cea1c786f186d50efbe71f6a10` |

No new 30-minute soak, export, native-route verification or press acceptance is claimed for this workaround. Other certificate gates retain their existing status.

Evidence: [receipt](acceptance/checkout-profile/receipt.json), [profile and byte hashes](acceptance/checkout-profile/owned-temp-checks/diagnostic.json), [EN console](acceptance/checkout-profile/full-suites/en/console.log), [RU console](acceptance/checkout-profile/full-suites/ru/console.log), and [post-suite source audit](acceptance/checkout-profile/post-suite-source-audit.json). The evidence is intentionally separate from the failed default-checkout logs.

## Freeze boundary

The original repository's game files, source manifest, protected fixtures, `TrustedData.gd`, legal/provenance records, immutable tag, and published release assets are untouched by this documentation. This scratch profile is neither a source repair nor a portable default-checkout guarantee. Source repair is forbidden under the present docs/artifacts-only freeze; the default fresh-clone blocker and announcement hold cannot be cleared by this experiment.

Git attribute precedence and text normalization: [official Git documentation](https://git-scm.com/docs/gitattributes). The critical-manifest test checks the committed policy text, not its effective overridden attributes; its PASS must not be called proof that the tagged LF checkout policy works.
