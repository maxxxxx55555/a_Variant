# Marchland Oaths 1.6.1 — acceptance certificate

Date: 2026-10-31. Automated Windows runtime checks accepted within the recorded scope. Runtime sources, both rendered suites and the exported binaries are from commit `c88a2a89a5f60febd87d68efae632c7db5ce9ea8`. Fresh-download verification of the published assets is recorded after upload in `acceptance-1.6.1/distribution.json`. Owner play/listening acceptance remains outstanding.

This edition is a patch. It closes one finding from the security review of 1.6.0: a checksum-only v1–v3 save was applied silently and then re-signed as an authenticated v4 save, so that path never needed the installation key. Such a file is now refused until the player confirms the import for that slot, in the active language; confirming applies and re-signs it, declining leaves the bytes untouched.

| Phase | Result and evidence |
|---|---|
| P1 Change | PASS: silent checksum-only import removed; explicit localized confirmation added; schema, slots and autosave rules unchanged. |
| P2 Regression | PASS: `tests/test_legacy_import.gd` asserts refusal, pending state, dialog texts, confirmed import, re-signing and byte-identical refusal in RU and EN; `tests/test_legacy_migration.gd` and `tests/test_oath_migration.gd` exercise the shipped 1.1 fixtures through the same two-step path. |
| P3 EN/RU | PASS: 83 rendered full-campaign cases per locale, 810 catalog keys, canonical copy and localization checks; `acceptance-1.6.1/suites.json`. |
| P4 Art/UI | PASS within retained presentation: the one new surface is reviewed at native size in both locales; `acceptance-1.6.1/visual-review.json`, `GALLERY_ACCEPTANCE_1.6.1.md`. |
| P5 Integrity | PASS: signed bounded saves, atomic backup/recovery, critical data anchoring, encrypted public pack, physical exclusion of the private verifier, pack and native contracts. |
| P6 Mechanics | PASS: 32 mechanics × 8 columns = 256 cells executed in RU and EN; 50 seeded cycles per locale with save/load identity assertions and no node growth. |
| P7 Acceptance | PASS: bilingual rendered suites, 5/5 native exported-build routes, legacy 1.1/1.4.0/1.5.0 profile migration, and 3 complete campaign loops in 2546 s of measured runtime. |
| P8 Distribution | PASS: clean main/CI, exact shipping bytes, licenses and secrets, immutable prior releases, published ZIP and sums; receipt below. |

## Exact public binaries

EXE SHA256: `4db12ce899fdb19148b3307b21a2549d3fb21ea44651c430978f21c479efa50f`. PCK SHA256: `ad3b39ea572871e0fc109a0efa8565b8084a8c6f8a6b06cd7a3d20aebba0c287`. QA pack (unpublished) EXE SHA256: `d6a8ac833d97e1a7ae9c370948d6c6b8affa67f69b84f0d12c84371a79cace30`, PCK SHA256: `51c2c79b4165bfd7113a6ee0890ea7aee79e9593bd1aa36c75ce0ee8a85779fa`. The ZIP checksum is stored beside its exact filename in `MarchlandOaths-SHA256SUMS-1.6.1.txt`; a ZIP cannot embed its own checksum.

## Scope and limitations

Automated checks are finite and were executed on one Windows host with an AMD integrated GPU under the Compatibility renderer. They do not replace a human playtest or a listening review, and they do not prove the absence of every defect. The measured soak samples object, resource and node counts after each completed campaign loop; operating-system allocator variation is measured, not described as literal zero-byte growth. Old failed attempts remain evidence and are not counted as passes.

Portable EXEs are not Authenticode signed. Android, store certification and console wrappers are outside this Windows release. This patch removes a silent state-injection path; offline integrity still resists ordinary corruption and editing without preventing an owner from patching a local binary, and the custom native template necessarily contains the pack-decryption key. The stock Godot editor cannot mount the encrypted pack, which `acceptance-1.6.1/pack-audit.json` records.

After the gated release and the owner checks in [HANDOFF](HANDOFF.md), this edition may be announced and distributed within these limits.

## Published distribution receipt

[Marchland Oaths 1.6.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.6.1) — distribution assets `MarchlandOaths-Windows-1.6.1.zip` (478,396,417 bytes, SHA256 `845bc95693354f678c785524210f005cf2a57e50a9a49ab66c86f80d92648567`) and `MarchlandOaths-SHA256SUMS-1.6.1.txt` (99 bytes, SHA256 `3ea20674cc19235b72fa3b1e5b147355dc602d0e3b747f4fce786f150bf831d8`). `sha256sum --check` on the sums file reports OK (exit 0). The fresh download of the published assets and a boot of the downloaded executable are recorded in `acceptance-1.6.1/distribution.json`.
