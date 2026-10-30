# Marchland Oaths 1.6.0 — acceptance certificate

Date: 2026-10-30. Automated Windows runtime checks accepted within the recorded scope. Runtime sources, both rendered suites and the exported binaries are from commit `9c0c145d8512cc9b667ea71cc36d33925a73e5ee`; the tag adds only documentation and the soak driver's teardown-aware watchdog, with the exact file list in `acceptance-1.6.0/distribution.json`. Fresh-download verification of the published assets is recorded after upload in `acceptance-1.6.0/distribution.json`. Owner play/listening acceptance remains outstanding.

| Phase | Result and evidence |
|---|---|
| F1 Content | PASS: complete campaign/life route, victory and defeat, Second Oath cycle, promise/mechanics matrices and contracts. |
| F2 EN/RU | PASS: 82 rendered full-campaign cases per locale, 806 catalog keys, canonical copy and localization checks; `acceptance-1.6.0/suites.json`. |
| F3 Art/UI | PASS within retained stylized presentation: 56 gallery frames reviewed at native size in both locales and both viewports; `acceptance-1.6.0/visual-review.json`, `GALLERY_ACCEPTANCE_1.6.0.md`. |
| F4 Audio | PASS: 42 WAV assets, exact provenance hashes, four distinct moods, both finales, separate hit-stop-safe cues and independent controls. Silent QA is not human listening approval. |
| F5 Integrity | PASS: signed bounded saves, atomic backup/recovery, critical data anchoring, encrypted public pack, physical exclusion of the private verifier, pack and native contracts. |
| F6 Mechanics | PASS: 32 mechanics × 8 columns = 256 cells executed in RU and EN (39 sources, 80 logs); 50 seeded cycles per locale with save/load identity assertions and no node growth. |
| F7 Acceptance | PASS: bilingual rendered suites, 5/5 native exported-build routes, legacy 1.1/1.4.0/1.5.0 profile migration, and a measured soak of 3 complete campaign loops in 2563 s. |
| F8 Distribution | PASS: clean main/CI, exact shipping bytes, licenses and secrets, immutable prior release, published ZIP and sums, fresh remote `sha256sum -c` exit 0; receipt below. |

## Exact public binaries

EXE SHA256: `41533c753b476427dc225a39e6b8945f275ca5128a2ef4553322b500a61d0b42`. PCK SHA256: `78582396d2c3333c38bea444b18da1f05da831c9e9655e4168f88c2c1f9f2166`. QA pack (unpublished) EXE SHA256: `3dd7548b4e76657c593817adc80c9d7eb6760cbd580174c1eae56a76cbe5cfc1`, PCK SHA256: `922783cc42282e11764715f2a80370bec6f979fcc6fd9d8ef96d0b4bfc30534f`. The ZIP checksum is stored beside its exact filename in `MarchlandOaths-SHA256SUMS-1.6.0.txt`; a ZIP cannot embed its own checksum.

## Scope and limitations

Automated checks are finite and were executed on one Windows host with an AMD integrated GPU under the Compatibility renderer. They do not replace a human playtest or a listening review, and they do not prove the absence of every defect. The measured soak runs complete campaign loops with pause, save/load and inventory checkpoints; object, resource and node counts are sampled, never estimated. Operating-system allocator variation is measured, not described as literal zero-byte growth. Old failed attempts remain evidence and are not counted as passes.

Portable EXEs are not Authenticode signed. Android, store certification and console wrappers are outside this Windows release. Offline integrity resists ordinary corruption and editing but cannot prevent an owner from patching a local binary. The custom native template necessarily contains the pack-decryption key; encryption is not invulnerable DRM. No secrets or private profiles are distributed as loose files. The stock Godot editor cannot mount the encrypted pack, which `acceptance-1.6.0/pack-audit.json` records.

After the gated release and the five owner checks in [HANDOFF](HANDOFF.md), this edition may be announced and distributed within these limits.

## Published distribution receipt

Distribution assets: `MarchlandOaths-Windows-1.6.0.zip` (451,817,849 bytes, SHA256 `dbc2d82a5d295cfd40a40d190eb0e1f96e4373e46bc8d84746b47f96bf761620`) and `MarchlandOaths-SHA256SUMS-1.6.0.txt` (99 bytes, SHA256 `a1f42da909ac50673712fbd56635ed6bb6a711a36131295faa0adf1ca4e81cec`). `sha256sum --check` on the sums file reports OK (exit 0). The fresh download of the published assets is verified after upload and recorded in `acceptance-1.6.0/distribution.json`.
