# Marchland Oaths 1.6.2 — acceptance certificate

Date: 2026-11-10. Source-gate checks accepted within the recorded scope. Runtime sources are from commit `f7a3155` plus the 1.6.2 completion commit on top of it (patch notes, acceptance evidence, version metadata, removal of two unused autoload scripts). The rendered full-campaign gate and the published distribution are **not** part of this certificate: the last executed rendered gate is the 1.6.1 one, and no v1.6.2 release exists yet. Owner play/listening acceptance remains outstanding.

This edition is a patch. It closes two ways a checksum-only v1–v3 save could still be applied after the 1.6.1 confirmation: a declined file could be promoted into the slot's authenticated backup by a later ordinary save, and an answer given for one file could be applied to different bytes swapped in while the dialog was open. The first is closed by trusting a previous body in `_store` only from the exact file just confirmed; the second by binding consent to a SHA-256 digest of the exact file text, per slot.

| Phase | Result and evidence |
|---|---|
| P1 Change | PASS: declined checksum-only body is no longer promoted into an authenticated backup (preserved as `.rejected` instead); consent is bound to the file digest, not the pathname; prompts are per slot. `scripts/autoload/SaveSystem.gd`, `docs/RELEASE_1.6.2.md`. |
| P2 Regression | PASS (asserted in code, not re-executed here as a rendered run): `tests/test_legacy_import.gd` asserts refusal, pending state, dialog texts, confirmed import, re-signing, byte-identical refusal, the declined-then-saved sequence and the swapped-file refusal in RU and EN; `tests/test_legacy_migration.gd` and `tests/test_oath_migration.gd` exercise the shipped 1.1 fixtures through the same two-step path. |
| P3 EN/RU | PASS (source gate): 811 catalog keys per locale, identical key sets, no missing translation; copy contract PASS. Rendered cases not re-run in this completion; last executed rendered gate is `docs/acceptance-1.6.1/suites.json` (83 per locale). |
| P4 Art/UI | PASS within retained presentation: the one touched surface is reviewed at native size in both locales; `docs/acceptance-1.6.2/visual-review.json`, `docs/GALLERY_ACCEPTANCE_1.6.2.md`. |
| P5 Integrity | PASS: signed bounded saves, atomic backup/recovery, critical data anchoring, encrypted public pack, physical exclusion of the private verifier, pack and native contracts (as in 1.6.1; no save-format change). |
| P6 Mechanics | PASS: 32 mechanics × 8 columns = 256 cells re-executed in RU and EN for 1.6.2 (`test_mechanics_matrix`: `EXECUTED_PASS` in ru,en). |
| P7 Acceptance | PASS (headless source gate): executed in Godot 4.7 Stable on Linux on a full checkout — editor import exit 0, strict warning gate 105/105 (49 categories as errors), Python contracts 10/10, `tests/run_tests.py` headless 79/79 Godot cases, exit 0. Rendered suites, soak and native exported-build routes not re-run; see `docs/acceptance-1.6.2/suites.json`. |
| P8 Distribution | PENDING: no v1.6.2 ZIP, sums or tag exist yet. The encrypted export requires the private template and key held outside the repository; see `docs/acceptance-1.6.2/distribution.json`. |

## Exact public binaries

None for 1.6.2 yet. The 1.6.1 binaries remain the latest published ones (EXE SHA256 `4db12ce899fdb19148b3307b21a2549d3fb21ea44651c430978f21c479efa50f`, PCK SHA256 `ad3b39ea572871e0fc109a0efa8565b8084a8c6f8a6b06cd7a3d20aebba0c287`, ZIP SHA256 `845bc95693354f678c785524210f005cf2a57e50a9a49ab66c86f80d92648567`).

## Scope and limitations

Source-gate checks are finite and were executed on a Linux host with Godot 4.7 Stable, on a full checkout of the 1.6.2 completion (strict compile 105/105, Python contracts 10/10, headless gameplay gate 79/79). They do not replace a human playtest or a listening review, and they do not prove the absence of every defect. The rendered gate, soak, native routes and published-binary smoke check were not re-run for 1.6.2 and must be run before the ZIP is published.

Portable EXEs are not Authenticode signed. Android, store certification and console wrappers are outside this Windows release. This patch removes two silent state-injection paths; offline integrity still resists ordinary corruption and editing without preventing an owner from patching a local binary, and the custom native template necessarily contains the pack-decryption key. The stock Godot editor cannot mount the encrypted pack, which `acceptance-1.6.1/pack-audit.json` records.

After the rendered gate, the exported-build verification, the owner checks in [HANDOFF](HANDOFF.md) and publication of the ZIP with a fresh `sha256sum -c` receipt, this edition may be announced and distributed within these limits. Until then, do not announce 1.6.2 as released.

## Published distribution receipt

None yet. When the release is published, record it here and in `docs/acceptance-1.6.2/distribution.json`: tag, tag commit, ZIP name and bytes, ZIP SHA256, sums file and SHA256, and the fresh-download `sha256sum -c` result with exit code.
