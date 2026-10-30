# Marchland Oaths 1.6.0 — final release report

Release URL: [Marchland Oaths 1.6.0](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.6.0). Runtime sources, both rendered suites and the exported binaries are from commit `9c0c145d8512cc9b667ea71cc36d33925a73e5ee`. The tagged tree adds only documentation and the soak driver's teardown-aware watchdog — no runtime file differs — and the exact file list is stored in `acceptance-1.6.0/distribution.json`.

Automated acceptance at that tree: EN 82/82, RU 82/82 rendered full-campaign cases; executed mechanics matrix 32 mechanics × 8 columns = 256 cells in both locales; 50 seeded cycles per locale; a measured soak of 3 complete campaign loops in 2563 s; 5/5 native exported-build routes; 4/4 encrypted export artifacts audited against the shipped trust anchor; 56 reviewed gallery frames. Full receipts: [certificate](ACCEPTANCE_CERTIFICATE.md), [suite evidence](acceptance-1.6.0/suites.json), [mechanics execution](acceptance/mechanics-execution-1.6.0.json), [announcement kit](ANNOUNCE_KIT.md).

## Goals G1–G7

| Goal | Result | Executed evidence | Rendered evidence |
|---|---|---|---|
| G1 Second Oath / New Game+ | PASS: four authored oaths, carried roster/gear/titles/difficulty, per-cycle scaling, banner in finale/save list/credits, stacking cycles | `tests/test_second_oath.gd`, `tests/test_oath_migration.gd`, `tests/test_campaign_finale.gd`, both 60-objective routes | `ending-staged`, `credits` |
| G2 World Codex | PASS: 25 entries unlocked by real events, locked/unlocked split, protected-profile state | `tests/test_codex.gd`, `tests/test_oath_migration.gd` | `codex` |
| G3 Quest tracker | PASS: HUD objective, measured distance, compass, map marker, toasts, joint teardown, pause persistence | `tests/test_quest_tracker.gd`, `tests/test_navigation_matrix.gd` | `homestead`, `world-map` |
| G4 Combat feel | PASS: bounded hit-stop (60–90 ms, 75 ms default, off under reduced motion), flash, recoil, spark, damage numbers, block cost 8 → 30% | `tests/test_combat_feel.gd`, `tests/test_comfort_preferences.gd` | no dedicated frame: feel is asserted in engine, not photographable |
| G5 Loot feel | PASS: rarity colour/glow/halo, pitched chime, pickup pop, shared accent from ground to bag | `tests/test_loot_feel.gd`, `tests/test_audio.gd` | `inventory` |
| G6 Settlement tiers | PASS: four visible tiers from real built levels (1/6/15/25), upgrade cue, seasonal tint | `tests/test_settlement_evolution.gd` | `settlement`, `village-rain` |
| G7 Local statistics | PASS: campaigns, regions, peak wealth, playtime, per-difficulty rows, local-only statement | `tests/test_stats.gd` | `stats` |

## Design pass: before → after

| Surface | 1.5.3 baseline | 1.6.0 |
|---|---|---|
| Palette | inherited muted gold/ink, ad-hoc tints | eight-point token set applied to every surface; semantic sage/brass/danger fills replace colour-only meaning |
| Typography | two display faces, mixed sizes | Literata display + Manrope UI scales with tabular numerals on statistics |
| Icons | mixed authored and text-only controls | authored icon set covering every button and tab; label always present next to the icon |
| Motion | drift, pop and breathing effects always on | reduced-motion support stops drift, pop and halo breathing without hiding information |
| Galleries | 26 frames, 1280×720 only, EN/RU | 56 frames, 14 screens × 2 locales × 2 viewports (1280×720, 1920×1080) in `docs/galleries/1.6.0/` |

The four defects the capture pass found (raw Codex tab names, unlabeled Codex close, danger-red healthy meters, clipped eighth faction) are fixed and recaptured; the review record is [GALLERY_ACCEPTANCE_1.6.0.md](GALLERY_ACCEPTANCE_1.6.0.md).

## First fifteen minutes

1. The title screen states the edition and carries the authored icon set and focus treatment.
2. The opening region teaches movement, interaction and one real objective inside a live settlement.
3. The HUD objective, compass and distance readout describe the same target within the first quest.
4. The first combat lands with hit-stop, a flash, a spark and a damage number on the first three hits.
5. The first settlement has a visible tier and a seasonal sky that matches the weather.
6. The Codex opens its first entry from an ordinary action — entering the first town — rather than from a menu.

## Mechanics matrix delta

| Edition | Mechanics | Columns | Cells | Execution record |
|---|---|---|---|---|
| 1.5.2 | 24 | 8 | 192 | mapped, `EXECUTED_PASS` |
| 1.6.0 | 32 | 8 | 256 | mapped, `EXECUTED_PASS` in RU and EN (39 referenced sources, 80 executed logs) |

The contract refuses to publish if any referenced source's bytes changed after the evidence was produced; it triggered exactly that refusal once during this cycle and evidence was regenerated.

## QA summary

| Check | RU | EN |
|---|---|---|
| Rendered full-campaign cases | 82/82 | 82/82 |
| Complete 60-objective routes | diplomatic + military PASS | diplomatic + military PASS |
| Executed mechanics route | PASS | PASS |
| Seeded fuzz | 50 seeds, 25 inside the Second Oath, node growth 0 | same |
| Legacy 1.1 profiles and protected 1.4.0/1.5.0 saves | PASS | PASS |
| Python contract chain (15 contracts) | PASS | shared |
| Strict compile gate | 105 shipping scripts, 49 warning categories as errors | shared |
| Static census | 0 dead code, 0 orphan sidecars, 0 dev markers | shared |

Logs for every case ship in `acceptance-1.6.0/suite-ru/` and `acceptance-1.6.0/suite-en/` with per-case SHA256 in `suites.json`.

## Performance against the v1.5.3 baseline

| Metric | v1.5.3 baseline (`01f7174`) | 1.6.0 (`9c0c145`) | Change |
|---|---|---|---|
| Scene load | 7821 ms | 7861 ms | +0.51% |
| Frames per second | 60.00 | 60.02 | +0.03% |
| Draw calls | 341 | 356 | +15 |
| Primitives | 294869 | 295509 | +640 |

Three runs per tree of the same scripted rainy-village camera on one Windows host with an AMD integrated GPU; medians shown, every sample recorded in `acceptance-1.6.0/perf.json`. Absolute figures vary with drivers and background load, so this is a smoke comparison, not a benchmark suite.

## Artifacts

| Asset | Bytes | SHA256 |
|---|---|---|
| `MarchlandOaths.exe` | 248071864 | `41533c753b476427dc225a39e6b8945f275ca5128a2ef4553322b500a61d0b42` |
| `MarchlandOaths.pck` | 176808620 | `78582396d2c3333c38bea444b18da1f05da831c9e9655e4168f88c2c1f9f2166` |

The public pack is directory- and file-encrypted; the private QA pack is never published. A stock Godot editor cannot mount the encrypted pack (`acceptance-1.6.0/pack-audit.json`). The ZIP and sums digests are recorded in the published distribution receipt below, because an archive cannot embed its own checksum.

## Music checksums

Unchanged from 1.5.x; re-verified against the shipped files.

| Mood/cue | Title | SHA256 |
|---|---|---|
| exploration | Stone Path to Dusk | `928d3e830ab86c2ef9a170658fd5405a7b883e1d5c90e3481ef93afdd21d5813` |
| settlement | Hearths Among the Hills | `78749767a35ed41dcf151579f2a92c3479b90a6672984eef70aac05ff61d0315` |
| combat | Steel and Rain | `f43353c344afffd1d4982dfeeb6ed55537cc5feec5ce1e7a623a01edf95ce921` |
| war | Standards at Dawn | `4e52901ed029631e514f0c2994fe2122492f9e428f14e5c1f791e68de6337ed3` |
| victory | Oaths Remembered | `1ccb20ebe5767031c1699ddf42d2cd7f87d29f8c2c429d6450ffa21b3c7608b2` |
| defeat | The Last Watch | `035c080389e01cf7dd2fb030a6f150e4afa6e41c97850fdfc0785641cdaa34ca` |

## Open questions and limits

- Portable Windows x64 executables are not Authenticode signed; Windows shows its normal warning.
- Automated checks are finite and were executed on one Windows host with an AMD integrated GPU. They are not a human playtest, a listening review, or a performance guarantee on other hardware.
- Offline integrity resists ordinary corruption and editing; it is not DRM and cannot stop an owner from patching a local binary.
- The custom native template necessarily contains the pack-decryption key. The pack is encrypted and audited; the key is not published.
- A CI run of the import step aborted once inside the Ubuntu runner's allocator (`realloc(): invalid next size`) and passed on an immediate re-run of the identical commit; it is recorded here as a runner-side event, not a game change.
- The soak harness previously lost its process when a real death released the world in a later cycle; the harness now reports that case and always writes its measured record (see [BUG_REGRESSIONS](BUG_REGRESSIONS.md)).

## Русский

Автоматическая приёмка выполнена на дереве `9c0c145d8512cc9b667ea71cc36d33925a73e5ee`: в обеих локалях пройдены все 82 отрисованные полнокампанейские проверки, включая две полные кампании по 60 целей; матрица механик 32×8=256 ячеек имеет исполненные доказательства в RU и EN; 50 сидовых циклов на локаль; измеренный soak: 3 полные петли кампании за 2563 с, без утечек и осиротевших узлов; нативные маршруты на экспортированных сборках: 5/5 маршрутов (три победы, железная смерть и отказ публичной сборки); 4 из 4 зашифрованных артефактов, критические данные сверены с расшифрованным содержимым; 56 кадров галереи проверены вручную.

Ограничения: EXE не подписан, проверки не заменяют ручной прогон и прослушивание, офлайн-защита не является DRM. Контрольные суммы, URL релиза и приёмка — в [сертификате](ACCEPTANCE_CERTIFICATE.md) и [HANDOFF](HANDOFF.md).

## Published distribution receipt

Distribution assets: `MarchlandOaths-Windows-1.6.0.zip` (451,817,849 bytes, SHA256 `dbc2d82a5d295cfd40a40d190eb0e1f96e4373e46bc8d84746b47f96bf761620`) and `MarchlandOaths-SHA256SUMS-1.6.0.txt` (99 bytes, SHA256 `a1f42da909ac50673712fbd56635ed6bb6a711a36131295faa0adf1ca4e81cec`). `sha256sum --check` on the sums file reports OK (exit 0). The fresh download of the published assets is verified after upload and recorded in `acceptance-1.6.0/distribution.json`.
