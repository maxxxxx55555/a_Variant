# Marchland Oaths 1.5.1 — acceptance certificate

Issued: 2026-10-27, Europe/Moscow. Cycle started2026-10-26.

**Verdict: NOT ACCEPTED / ANNOUNCEMENT HOLD.** The requested clean-tag gate failed. The existing Windows download remains published and byte-unchanged; its finite historical/native passes are not a substitute for fresh source acceptance. No new feature, original-repository game-file edit, tag move or release-asset mutation was performed. Godot normalized newline-only import metadata in scratch checkouts; those files are not copied back to main.

Independent revalidation here means new source checkouts/import caches/profiles and a second automated read-only review. It is not independent human certification or audible listening approval.

## Identity and zero game delta

| Item | Evidence |
|---|---|
| Public release | [v1.5.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.1) |
| Immutable release commit | `006c164895d8d70fc2a72a61610b2ad27bb9e97e` |
| Immutable source tree | `2ddab3608b569c15c373406b440b8a78baec9c5f` |
| Baseline main before this docs cycle | `dff71bac0d09b4766c85a3b98a2c22bf58ac2348` |
| Compare tag...main | Only docs/ paths; final receipt enumerates all certificate/kit/evidence/press additions |
| Release composition | Exactly one ZIP + one canonical sums; asset IDs/digests unchanged |
| Fresh source isolation | Existing guard rescanned tag checkout:0disallowed markers; documented shared-tool exceptions retained |
| Baseline strict CI | [run40371193240](https://github.com/maxxxxx55555/a_Variant/actions/runs/40371193240) success; latest docs-head CI is in the final session receipt |
| Human owner acceptance | NOT PERFORMED; five HANDOFF checks remain necessary after automated blockers are resolved |

Fresh public download verification:

```text
$ sha256sum -c MarchlandOaths-SHA256SUMS-1.5.1.txt
MarchlandOaths-Windows-1.5.1.zip: OK
exit: 0
```

- `MarchlandOaths-Windows-1.5.1.zip` — SHA256 `8e392c3708d907790906d7c0b7a4794a3c987b507456f74b87831eae553a3b7d`; 318466595bytes.
- `MarchlandOaths-SHA256SUMS-1.5.1.txt` — SHA256 `fdd5675109e86824586cfe05eb690f47b5da061e6f0727305eaea47ea938ed81`; 99bytes.

[Published binary smoke receipt](acceptance/published-binary-smoke.json): actual freshly downloaded EXE/PCK ordinary boot and public verifier rejection pass. These checks are explicitly not new tag exports or private verifier runs. The fresh-source warning is not inferred to exist in the unchanged distributed Windows binary; published-binary results are reported separately.

## Current mandatory acceptance results

| Requirement | Status | Evidence |
|---|---|---|
| §2.1–2.5 docs delta/assets/branches/isolation/CI | PASS scoped metadata audit | API snapshot/final receipt; fresh sums; tag guard; compiler CI |
| §3.1 complete rendered RU/EN suites | FAIL | Both full runner commands exit1 in Python prechecks;0Godot cases ran |
| §3.2 public/private tag export; authorized verifier; victory/defeat | BLOCKED | Public and QA preflight both exit2 because critical-data manifest is stale; no new binaries generated |
| §3.3 original1.4.0 and1.5.0 saves | PARTIAL | Exact original private-copy read loads pass; profile/key/original bytes preserved; new writes, stable write round-trip and tamper suite acceptance blocked |
| §3.4 fresh bilingual gallery | FAIL visual acceptance | 24new frames reviewed; integrity warning obstructs screens; staged/failed fixtures are labelled |
| §3.5 music hashes/paths/channels/durations | PASS for six music WAVs; FAIL full audio contract | Four distinct mood paths, six unique WAV hashes; SFX generator-source provenance mismatch |
| §3.6 three verifier runs and30minute soak | NOT ACCEPTED | New verifier cannot be built; measured soak121.651s, rawFAIL, source integrity anomalies present |

## Phase sign-off F1–F8

| Phase | Current sign-off | Evidence |
|---|---|---|
| F1 content | Historical published-edition scope retained; not a new full-route pass | FINAL_REPORT.md and old finite native evidence |
| F2 localization | Partial; fresh complete suite not accepted | suite-en.log / suite-ru.log; checkout copy findings where applicable |
| F3 art | FAIL fresh presentation acceptance | New warning-obstructed frames and visual-review.json |
| F4 audio | Music WAVs PASS; source provenance FAIL | audio-verification.json / audio-assets.log |
| F5 hardening | New source export BLOCKED | Public and QA export preflight both exit2 |
| F6 stability/mechanics | NOT REACCEPTED under current source gate | Measured soak acceptance, source integrity anomalies |
| F7 complete validation | FAIL | Both full runner commands abort in prechecks;0Godot gameplay cases |
| F8 existing publication | Published download integrity PASS; new publication forbidden; announcement HOLD | Fresh checksums/public smoke; immutable assets; final external receipt |

## Fresh runner output

| Locale | Result | Exit | Godot invocations | Console SHA256 |
|---|---|---|---|---|
| RU | FAIL | 1 | 0 | `575f849b5ca51cd8beb8e34e849eeb01b1767fe3dcd95c0fa865f3d76bcd332d` |
| EN | FAIL | 1 | 0 | `575f849b5ca51cd8beb8e34e849eeb01b1767fe3dcd95c0fa865f3d76bcd332d` |

Logs: [RU](acceptance/suite-ru.log), [EN](acceptance/suite-en.log). The complete existing runner was invoked with `--rendered --language ru/en --audio-driver Dummy`; its early precheck failures mean the rendered gameplay cases did not execute. No fixture, expected hash, test or trust rule was weakened to obtain a pass.

## Blocking source-byte findings

The critical manifest expects CRLF working-copy bytes, while the immutable tag stores LF for7JSONfiles. Converting those tag bytes to CRLF reproduces every expected digest. Read-only safe mode therefore activates on legitimate fresh source and disables progress/settings writes. Both fresh export preflights correctly refuse to bless those bytes.

| Resource | Expected manifest SHA256 | Actual immutable-tag/fresh SHA256 |
|---|---|---|
| `assets/audio/catalog.json` | `e430a4cd11299c2eee5b6384d2815b39a99dc9e007525ff7697ee99410536bda` | `edeb723c24fb0ddaa81607178aa39a6f1f130ccf50fe2e824dfa2090e6202cf5` |
| `data/balance/alchemy.json` | `2ada2868c9b3f77ed01f10e16fed7c895588c37c5e5e35acc88d730361379776` | `b9919d6d62a48c6f603fb6b62c01ca0fad82dbb395f16a37e119f6b314225cdb` |
| `data/balance/buildings.json` | `febfea72c844aab815fa046d0882b0cec622855d309d8fab954d0d0caafb550d` | `dd01ee5c72460426ea85184c570ebb7dec7bc854981494cceb2409c9249471e4` |
| `data/balance/campaign.json` | `f61783f80e27c1c76130b3984b04ad723f0000bb7bb9d36321842ae67c9776e8` | `28232f520fb2e9398a15415febbf3d690f6bfc7a94c6e089e2fe063ec3d75516` |
| `data/balance/crafting.json` | `34600efe06fd76b78f415d1c39a8deb5d2fe6fe4afd46f675a75c115f980f5e5` | `67bc45bff3fb9d8145f47e7927a2b7a93c5bca088da17e3b0ff59f6bb4ad6028` |
| `data/balance/equipment.json` | `1196526425f05bb0af960686df68c80ce1c973ad3edba6d1b70b40d15d4f51bb` | `ad180d92426e5b2a25be074a8d1c326fb1063bb0b6fdd798ad463431acdcc62e` |
| `data/balance/localization.json` | `7136fe0c7d92f411ec8e5a329c0b5b516e92917f40ae898ddac446821146efac` | `57477a064d302aaf23af2fce84772aeb19aee9494919e96c4859e775210a2cc2` |

The full runner reaches the SFX-generator provenance assertion and aborts before any Godot case.36scratch .import metadata differences are newline-only; they are separate from the real critical-data mismatch.

The interface SFX provenance additionally records a CRLF generator hash instead of the LF tagged Python file. Music recordings themselves match their recorded WAV hashes. The discrepancy is source-byte/provenance portability, not evidence that a different composition was substituted. Detailed proofs: [source blockers](acceptance/source-blockers.json), [audio verification](acceptance/audio-verification.json), [public export preflight](acceptance/public-export-preflight.log), [QA export preflight](acceptance/qa-export-preflight.log).

Correcting canonical data/trust, CSV checkout policy where applicable and generator-source provenance would require changes outside this documentation-only freeze and a new acceptance cycle. No such correction was made; tags/assets were not republished.

## Soundtrack evidence

| Mood | File | Actual channels/rate/duration | Actual WAV SHA256 |
|---|---|---|---|
| exploration | `stone_path_to_dusk.wav` | 2 / 32000Hz / 117.304s | `928d3e830ab86c2ef9a170658fd5405a7b883e1d5c90e3481ef93afdd21d5813` |
| settlement | `hearths_among_the_hills.wav` | 2 / 32000Hz / 124.000s | `78749767a35ed41dcf151579f2a92c3479b90a6672984eef70aac05ff61d0315` |
| combat | `steel_and_rain.wav` | 2 / 32000Hz / 124.000s | `f43353c344afffd1d4982dfeeb6ed55537cc5feec5ce1e7a623a01edf95ce921` |
| war | `standards_at_dawn.wav` | 2 / 32000Hz / 124.000s | `4e52901ed029631e514f0c2994fe2122492f9e428f14e5c1f791e68de6337ed3` |
| victory | `oaths_remembered.wav` | 2 / 32000Hz / 20.000s | `1ccb20ebe5767031c1699ddf42d2cd7f87d29f8c2c429d6450ffa21b3c7608b2` |
| defeat | `the_last_watch.wav` | 2 / 32000Hz / 20.000s | `035c080389e01cf7dd2fb030a6f150e4afa6e41c97850fdfc0785641cdaa34ca` |

[Music contract](acceptance/music-wavs.log) passes4distinct mood recordings plus2finales. [Full audio-assets contract](acceptance/audio-assets.log) fails the generator-source SHA256 assertion. Automated wave/routing evidence does not establish human listening acceptance.

## Soak and save scope

Raw measured run: 121.651s, 1life/campaign loops, 1checkpoints. Engine counters: `{"nodes":{"first":65,"last":65,"delta":0,"all_constant":true},"resources":{"first":294,"last":294,"delta":0,"all_constant":true},"objects":{"first":2113,"last":2113,"delta":0,"all_constant":true},"orphans":{"first":0,"last":0,"delta":0,"all_constant":true}}`. OS private-byte quarter medians: `[1690050560, 1690185728, 1690185728, 1690222592]`, delta `172032`bytes. These are measured allocator/cache variations, not a literal zero-byte growth claim.

The campaign stopped after8quests at a failed ordinary manual save. Its121.651second run does not satisfy a30minute soak.

Fresh legacy loads verify only read compatibility and preserve original/profile/key bytes. Source writes remain blocked. Historical complete native wins, old-profile public-native upgrades,50seeded routes and the previous soak are retained as historical evidence, never relabelled as passes of this new source gate.

## All historical gate items revisited

The prior59-item publication gate was historical and passed on its recorded inputs. The table below revisits this repository's own items against the current acceptance cycle; it is not a new100%sign-off. The target-tag-free item is inapplicable because no new tag may be created.

| Original gate item | Current status | Evidence / scope |
|---|---|---|
| F1 completed and retained | HISTORICAL ONLY | Historical gate `f1c89509c002c05e3e586079970a0a00192bb858c649316e1f3141ee7806b652`; not counted as a new pass. |
| F2 completed and retained | PARTIAL / FAIL | Fresh copy/key evidence; Key/copy prechecks pass; no complete rendered sweep. |
| F3 completed and retained | FAIL | New gallery cases and visual-review.json; integrity modal visible. |
| F4 completed and retained | PARTIAL FAIL | 6WAV hashes valid; SFX generator-source SHA256 does not match provenance. |
| F5 complete | BLOCKED | Both fresh tag export preflights exit2; no new artifact created. |
| F6 complete | FAIL / NOT REACCEPTED | Fresh suites fail; source integrity activates read-only mode; soak not accepted. |
| F7 complete | FAIL / NOT REACCEPTED | Fresh suites fail; source integrity activates read-only mode; soak not accepted. |
| test_promise_matrix.py | PASS | Fresh supplemental-contracts receipt and inherited license checks. |
| test_license_bytes.py | PASS | Fresh supplemental-contracts receipt and inherited license checks. |
| every original promise indexed with tested scoped resolution | PASS inventory | Fresh promise matrix contract; edition exclusions retained. |
| every mechanics cell executed | HISTORICAL ONLY | Historical gate `f1c89509c002c05e3e586079970a0a00192bb858c649316e1f3141ee7806b652`; not counted as a new pass. |
| EN/RU final full source sweeps | FAIL / NOT REACCEPTED | Fresh suites fail; source integrity activates read-only mode; soak not accepted. |
| per-mood music provenance and audio acceptance | PARTIAL FAIL | 6WAV hashes valid; SFX generator-source SHA256 does not match provenance. |
| art direction and accepted real-engine galleries | FAIL | New gallery cases and visual-review.json; integrity modal visible. |
| hardening parity and exact native exports | BLOCKED | Both fresh tag export preflights exit2; no new artifact created. |
| legacy profiles preserved in source and actual public native | PARTIAL | Fresh read-only legacy load passes; new writes/round-trip and rebuilt native acceptance blocked. |
| 50 unique full cycles plus measured soak and 3 stability runs | FAIL / NOT REACCEPTED | Fresh suites fail; source integrity activates read-only mode; soak not accepted. |
| accepted logs clean and no known unresolved edition bugs | FAIL / NOT REACCEPTED | Fresh suites fail; source integrity activates read-only mode; soak not accepted. |
| exact-head hosted strict compilation | PASS compiler only | Baseline main CI40371193240 success; warning-only CI does not check these runtime-byte contracts. |
| Linux importer environmental failure investigated with 3 retries | HISTORICAL ONLY | Historical gate `f1c89509c002c05e3e586079970a0a00192bb858c649316e1f3141ee7806b652`; not counted as a new pass. |
| post-push repository tree identity and isolation | BASELINE PASS; final receipt pending | Initial docs-only metadata/isolation proof; final pushed documentation commit attested by accompanying SESSION_RECEIPT.json. |
| inherited license bytes and provenance | PARTIAL | 14 inherited license bytes pass; interface generator source provenance does not. |
| real committed checkout byte contracts | FAIL | Critical-data hashes and generator provenance fail; see source-blockers.json/audio-verification.json. |
| tracked tree credential/generated/foreign-content audit | PASS scoped audit | Fresh tag guard0disallowed markers; final docs-only diff/source and release immutability receipt. |
| actual private export keys absent from all tracked content | PASS scoped literal scan | literal-key-absence.json: raw/hex/Base64 key representations absent in tracked source plus new docs. Snapshot only; no exported-engine secrecy claim. Final HEAD scan is in the package receipt. |
| versions match and target tag is free | N/A new tag | Existing immutable version verified; tag creation is forbidden in this cycle. |
| exact final archives and delivery-name native boot | PASS published binary only | Current-cycle download SHA256/sha256sum-c and ordinary boot/public QA rejection pass. |
| default main; obsolete branches ancestry-reviewed | PASS | Baseline/final API branches and documented unique-content exception. |
| Android fallback explicit | N/A omitted | No Android artifact/runtime/store acceptance; no emulator available. |
| clean committed main | BASELINE PASS; final receipt pending | Final source/game delta0 and clean docs-only commit are attested after push in accompanying SESSION_RECEIPT.json. |

Final post-push/main/CI status is intentionally not pre-signed here. The accompanying handoff package contains SESSION_RECEIPT.json for the actual docs commit and its final CI; its main revision is later than this certificate baseline.

## Known limitations and owner handoff

Portable Windows executables have no Authenticode signature; normal Windows warnings can appear. Android/emulator and store certification are outside this Windows edition. One available Windows/GPU host and automated routes are not every-device certification, a human playtest, audible review, proof against every bug or unbreakable offline protection. Private installation/build key values or files are not included in the evidence or press files. [Literal source/docs scan](acceptance/literal-key-absence.json) found zero key representations. This says nothing about secrecy of native engine binaries, which necessarily contain their pack key.

The unique branch exception remains documented in FINAL_REPORT where applicable. The owner’s later checks are:1download+sha256sum-c,2launch and select EN/RU,3listen to four moods plus stingers and inspect credits,4save/Continue and test a backed-up1.4.0 profile,5verify filenames before distribution. See [HANDOFF.md](HANDOFF.md). These checks do not waive current mandatory source blockers.

The requested positive acceptance sentence is withheld because issuing it would contradict the observed failures. The announcement copy and eight images in [ANNOUNCE_KIT.md](ANNOUNCE_KIT.md) are rejected drafts.

Редакция не принята по текущему гейту; анонс приостановлен до устранения и повторной проверки обязательных блокеров.

## Supplemental checkout reproduction — 2026-10-27

The separate [diagnostic reproduction report](CHECKOUT_REPRODUCTION.md) records full rendered EN/RU passes after local checkout-serialization overrides. It preserves canonical tag blobs while deliberately changing selected scratch working bytes. Those overrides contradict the tagged LF checkout policy, so they do not clear the default-checkout failures or change this **NOT_ACCEPTED / ANNOUNCEMENT HOLD** verdict. No new export, soak or native acceptance is substituted. Original game files, tags and release assets remain unchanged.
