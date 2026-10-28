# Marchland Oaths 1.5.2 — acceptance certificate

Date: 2026-10-28 (Europe/Moscow). Automated Windows runtime checks accepted within the recorded scope. Final publication requires the external `release-gate.json` to report 100%; remote download verification is recorded after publication. Owner play/listening acceptance remains outstanding.

Runtime/export source: `6780cad9460a83559f891639f71ddd2672b21575`. Full-suite source: `ef48b6a9b953e9aa427c6bb33b7d350da9f59778`. Later documentation or test-only changes must retain byte-identical shipping source/assets; the final gate records this comparison. This certificate supersedes the earlier negative certificate for this patch only; old tags, assets and failure records remain unchanged.

| Phase | Result and evidence |
|---|---|
| F1 Content | PASS: complete campaign/life route, victory and defeat; promise/mechanics matrices and contracts. |
| F2 EN/RU | PASS: 67 Godot cases per locale, canonical copy and localization checks; `acceptance-1.5.2/suites.json`. |
| F3 Art/UI | PASS within retained stylized presentation: 26 actual frames inspected; `acceptance-1.5.2/visual-review.json`, new press set. |
| F4 Audio | PASS: exact provenance hashes, four distinct moods, finale cues, channels, durations, loops and independent controls. Silent QA is not human listening approval. |
| F5 Integrity | PASS: signed bounded saves, atomic backup/recovery, critical data anchoring, encrypted public pack and physically excluded private verifier; pack/native/source contracts. |
| F6 Mechanics | PASS: 50 distinct completed seeded routes; matrix assertions; no unexplained errors or integrity warnings. |
| F7 Acceptance | PASS: bilingual suites, 3 consecutive native victories plus defeat, legacy read/write round-trips and tamper rejection, 2683.422s measured normal soak with 3 complete loops. |
| F8 Distribution | Required external gate: clean synchronized main, shipping-byte parity, CI, licenses/secrets, exact ZIP+sums, immutable prior releases; fresh remote `sha256sum -c` after publication. |

## Exact public binaries

EXE SHA256: `f2b5a5b4aa70371576b39a4589db45fb2e05a49cdcd9bc4906ab2b6b5a0c5d83`. PCK SHA256: `435ae7b80424ebc79c0767d9317038faa38f522460cb8c4a5aef1efc09edda82`. The final ZIP checksum is stored beside its exact filename in the release sums file; a ZIP cannot embed its own final checksum.

## Scope and limitations

The normal soak has flat unloaded-cycle engine object/resource/node counts and zero orphans. Operating-system allocator variation is measured, not described as literal zero-byte growth. Old failed attempts remain evidence; they are not counted as passes. Public Exit/window-close/save-retry paths have actual-engine regressions. A desktop-control attempt produced an incorrect capture, and a later attempt showed a locked desktop. Both were stopped without blind input and are not counted as passes. Scripted gallery endings are explicitly labelled. Automated checks are finite and do not replace a human playtest or listening review.

Portable EXEs are not Authenticode signed. Android/emulator and store certification are outside this Windows release. Offline integrity resists ordinary corruption/editing but cannot prevent an owner from patching a local binary. The custom native template necessarily contains the pack-decryption key; encryption is not invulnerable DRM. No secrets or private profiles are distributed as loose files.

After the gated release and the five owner checks in [HANDOFF](HANDOFF.md), this edition may be announced and distributed within these limits.
