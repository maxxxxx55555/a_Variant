# Marchland Oaths — final release report

Closeout date: 2026-10-26. The accepted Windows release is handed to its owner. The new closeout commit contains documentation only; `main` is a docs-only descendant of the immutable release tag. Game files, source version, tag and distributed game bytes are unchanged by this closeout.

## Release identity and artifacts

| Field | Accepted value |
|---|---|
| Game / platform | Marchland Oaths / Windows x86_64 |
| Version / immutable tag | 1.5.1 / `v1.5.1` |
| Release URL | [v1.5.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.1) |
| Released source commit | `006c164895d8d70fc2a72a61610b2ad27bb9e97e` |
| Released source tree | `2ddab3608b569c15c373406b440b8a78baec9c5f` |
| Engine | Godot 4.7 Stable, compatibility renderer |
| Gate before publication | 59/59 checks; 100%; gate SHA256 `f1c89509c002c05e3e586079970a0a00192bb858c649316e1f3141ee7806b652` |

| Public artifact | Bytes | SHA256 |
|---|---|---|
| [MarchlandOaths-Windows-1.5.1.zip](https://github.com/maxxxxx55555/a_Variant/releases/download/v1.5.1/MarchlandOaths-Windows-1.5.1.zip) | 318466595 | `8e392c3708d907790906d7c0b7a4794a3c987b507456f74b87831eae553a3b7d` |
| [MarchlandOaths-SHA256SUMS-1.5.1.txt](https://github.com/maxxxxx55555/a_Variant/releases/download/v1.5.1/MarchlandOaths-SHA256SUMS-1.5.1.txt) | 99 | `fdd5675109e86824586cfe05eb690f47b5da061e6f0727305eaea47ea938ed81` |
| Distributed executable | — | `822a8e199af4579e51928dc770a48300a9f739d3930b956f7ff5d31d56db6334` |
| Distributed PCK | — | `ea2d5f42d69cb43e857e54e321c08b4a81e0836262807b586d1f4d945f2aeab8` |

The canonical checksum was already byte-correct and was verified unchanged against a fresh download.

Fresh ZIP and sums were downloaded from the published GitHub release, into a new directory. Exact checksum line bytes were compared before the real native BusyBox `sha256sum` command below; Python hashing was an additional independent check, not a substitute for this command.

```text
$ sha256sum -c MarchlandOaths-SHA256SUMS-1.5.1.txt
MarchlandOaths-Windows-1.5.1.zip: OK
exit: 0
```

## Completed F1–F8 work

| Phase | Delivered scope / acceptance |
|---|---|
| F1 content and loop | 60-objective campaign with exploration, trade, crafting, homestead, settlements, diplomacy, squads and battles; terminal iron-mode defeat and ordinary paid recovery; boot/loading hints, save-aware exits and comfort/settings flows. Explicit edition boundaries are retained in README and PROMISE_MATRIX. |
| F2 localization | 687 keyed entries, live EN/RU presentation, glyph/placeholder/copy checks, canonical saved IDs and original profile keys retained. |
| F3 art direction | Curated per-game art/font/UI direction and licensed assets; 50 accepted engine captures across EN/RU and 1280×720 / 1920×1080; focus, disabled states, layout and reduced-motion checks. See ART_DIRECTION.md and ASSET_REVIEW.md. |
| F4 audio | Four distinct background mood recordings plus victory/defeat cues; independent Master/Music/SFX/UI controls, contextual effects, routing/levels/seam/provenance checks. |
| F5 hardening | Authenticated bounded saves, atomic writes/backups, compiled critical-data trust and read-only safe mode, encrypted public packs and physical exclusion of private verifiers. |
| F6 mechanics | 24 mechanics / 192 executed cells; 50 distinct complete seeded runs; measured rendered soak 2628.797 seconds; 3 complete 60-objective campaigns; 21 checkpoints; zero orphan nodes and flat post-cycle structural counters. OS allocations varied and are measured, not claimed constant. |
| F7 final QA | Complete EN/RU suites below; three exact native complete victories, defeat route, real legacy 1.4.0 and 1.5.0 public-native migrations, tamper, encrypted pack parity, gallery and performance checks. |
| F8 release | Exact accepted public ZIP, licenses, separate sums, immutable tag, public bilingual release, server digests, isolated remote trees and clean pushed sources; final closeout only updates documentation/release checksum housekeeping. |

Named regression coverage includes: Companion and soldier lifetime, pause behavior, bounded exploration rewards, exact profile restoration and repeated iron-death/recovery callbacks. Accepted edition scope has no known unfixed defect in the tested scenarios and no unexpected final errors. Original failed RED and environmental diagnostics remain distinct from accepted final passes.

## QA by suite and locale

| Suite | Locale | Result | Retained console SHA256 |
|---|---|---|---|
| Complete Godot runner + Python contracts | EN | 62 invocations; PASS | `62afce43f0c18653689701317a9ee216228d4bed4de37a45351f0defaa443533` |
| Complete Godot runner + Python contracts | RU | 62 invocations; PASS | `57c0ffe95faa2c5b4aeb86d7ccf6dc9867d435b1e3596b9fe9158fe1d1c8be9c` |

The final full suites use Dummy audio to keep unattended QA quiet. Python contracts cover inherited licenses, promises, public exports, repository isolation, soundtrack and critical trust. Strict shipping/private compiler checks enforce all49 warning categories on 90 scripts. The released commit's [Shipping GDScript warnings CI](https://github.com/maxxxxx55555/a_Variant/actions/runs/40318626832) passed; new docs-only `main` commits trigger the same unmodified workflow. This report does not re-label older tests as runs of changed game code: there are no closeout game-code changes.

### Fresh native public/private guard rerun

The exact public EXE and matching PCK were hash-matched to the package manifest. Separate Windows QA export metadata and private executable SHA256 were checked. Each run used a new isolated profile. Public cases deliberately supply `GAME_QA=1`; the environment alone cannot unlock QA. The private missing-env case still rejects, and the authorized private route completes.

| Native case | Result | Exit | Console SHA256 |
|---|---|---|---|
| public-rejects-verifier | PASS | 64 | `2c21d3cdf5762f471a8f9ef46096cd98d3de0143074bce2f534ffe4c3e1a0985` |
| public-rejects-route | PASS | 64 | `2c21d3cdf5762f471a8f9ef46096cd98d3de0143074bce2f534ffe4c3e1a0985` |
| private-requires-env | PASS | 64 | `2c21d3cdf5762f471a8f9ef46096cd98d3de0143074bce2f534ffe4c3e1a0985` |
| private-accepts-verifier | PASS | 0 | `ce71a49dda940bc11b917578a3663518e4e1985f52ae1ba60fffd06594bff20a` |

```text
public --verify-build, GAME_QA=1: QA arguments require a private QA export and GAME_QA=1 (exit64)
public route-only argument, GAME_QA=1: QA arguments require a private QA export and GAME_QA=1 (exit64)
private --verify-build, GAME_QA=0: QA arguments require a private QA export and GAME_QA=1 (exit64)
private --verify-build, GAME_QA=1: NATIVE IRON DEATH: PASS (exit0)
```

The controlled private iron route also passes --defeat and exercises actual lethal-damage/UI/save callbacks; it is not a claimed independent manual death playthrough. Private verifier resources/build keys are absent from public downloads. The private QA executable is not a release asset.

## Save/data integrity and threat limits

Purpose-bound HMAC-SHA256, per-installation random keys, bounded/finite validation, exact finite-float metadata, stable schema4 domains, atomic replacement and authenticated backup recovery protect ordinary profile integrity. A changed critical-data manifest or payload enters localized read-only safe mode with compiled trusted fallback and no profile/key mutation. PCK entries/directories are encrypted; stock/wrong-key engines reject them. Native templates omit debugger/path-override support. See [SAVE-INTEGRITY.md](../SAVE-INTEGRITY.md).

Terminal iron death rejects repeated damage/reload/recovery; normal death retains the 20% gold recovery rule.

This is offline integrity protection. The owner of a machine can extract local keys, restore complete old profiles, inspect memory or modify a native executable. No server-authoritative anti-cheat, kernel protection or claim of invulnerability is supplied.

## Music: mood → file → actual WAV SHA256

| Mood | Tracked file | SHA256 |
|---|---|---|
| exploration | `assets/audio/stone_path_to_dusk.wav` | `928d3e830ab86c2ef9a170658fd5405a7b883e1d5c90e3481ef93afdd21d5813` |
| settlement | `assets/audio/hearths_among_the_hills.wav` | `78749767a35ed41dcf151579f2a92c3479b90a6672984eef70aac05ff61d0315` |
| combat | `assets/audio/steel_and_rain.wav` | `f43353c344afffd1d4982dfeeb6ed55537cc5feec5ce1e7a623a01edf95ce921` |
| war | `assets/audio/standards_at_dawn.wav` | `4e52901ed029631e514f0c2994fe2122492f9e428f14e5c1f791e68de6337ed3` |
| victory | `assets/audio/oaths_remembered.wav` | `1ccb20ebe5767031c1699ddf42d2cd7f87d29f8c2c429d6450ffa21b3c7608b2` |
| defeat | `assets/audio/the_last_watch.wav` | `035c080389e01cf7dd2fb030a6f150e4afa6e41c97850fdfc0785641cdaa34ca` |

These hashes were recomputed during closeout and match `assets/audio/music-provenance.json`. Background recordings and finales are actual Gemini/Lyria output, including Lyria RealTime recordings; they are not represented as human performances, exclusive copyrights or CC0 music. Separate synthetic interface/action SFX retain their own CC0 provenance. Sources/prompts/mastering/terms are in [SOUNDTRACK.md](../assets/audio/SOUNDTRACK.md), [music-provenance.json](../assets/audio/music-provenance.json), [LICENSE.md](../assets/audio/LICENSE.md) and the credits. No independent audible human listening review is claimed.

## Transfer audit, branches and post-push isolation

[AUDIT_RELOCATION.md](AUDIT_RELOCATION.md) records C1–C13. Historical mixed design copies were reduced to their proper project scope. Intentional shared tooling stays explicitly allowlisted. Original licensed assets remain with their proper project; all 14 inherited license files match the original1.4.0 release bytes. No new inter-project asset transfer occurred in final closeout.

Direct GitHub API audit of `v1.5.1` resolved annotated tag → commit → recursive tree `2ddab3608b569c15c373406b440b8a78baec9c5f`, fetched all 686 unique UTF-8 text blobs for 688 paths through the API, recomputed each Git blob SHA, and applied the existing guard's exact foreign/secret patterns and documented shared-tool/third-party-notice exceptions. Result: **PASS, 0 disallowed matches**. Binary/non-UTF-8 blobs are counted separately, as in the source guard. Both the immutable release tree and docs-only `main` receive isolation checks.

Only `main` remains on the remote and locally.

Main upstreams are explicitly `origin/main`; local branches equal remaining remote branches, ahead/behind0, with no unstaged/staged work after the documentation commit/push. New main history is allowed to differ from the tag only by these handoff/report documents. The accepted game tree and public ZIP hashes stay unchanged. The historical generated workflow commit-title exception remains documented in AUDIT_RELOCATION.md. Its public history was preserved. Hosted Linux import initially aborted before compilation; three subsequent complete same-head retries passed. Original diagnostic failure evidence remains retained.

## Open questions and honest limitations

No unresolved scoped-edition release blocker remains in the accepted finite scenarios. No extra remote branch remains.

Windows binaries are unsigned (no Authenticode certificate). Android is omitted because no emulator boots on this host; no Android runtime or store acceptance is claimed. One Windows AMD integrated-GPU host and automated native routes do not establish all-device compatibility, independent human playtest, universal absence of bugs, unbreakable security or AAA production scale. Measured engine/OS allocation and frame times are evidence for that host only.

Earlier Windows WASAPI device invalidation is retained as a rejected environmental run; three actual-audio retries passed, and final quiet repeats used Dummy. Owner listening and an independent ordinary play session remain recommended pre-announcement checks, not silently claimed completed.

The archive is immutable and does not contain these later documentation-only handoff files. Read current [HANDOFF.md](HANDOFF.md) for the five owner checks before announcement. All detailed raw evidence remains in the session output `release-1.5.1-and-2.0.0/final-closeout` with historical F1–F8 evidence alongside it; no private keys/profiles are published.
