# Owner checks 1.6.0 — what was executed, what was inspected, what is left for a person

The five owner checks in [HANDOFF](HANDOFF.md) exist because automated tests cannot hear a mix, judge a hit-stop by feel or decide whether a skyline reads well. This record closes everything in those checks that a machine can close, states the measured numbers, and names the small remainder that genuinely needs a person in front of the game.

## Method

The frames in `acceptance-1.6.0/owner-checks/` come from the **exported QA build** (`private_build/exports/qa/MarchlandOaths.exe`, an unpublished artifact that carries the same runtime code as the public pack plus the verifier). It ran at 1280×720 with the Compatibility renderer, an isolated profile and `GAME_LANGUAGE=ru|en`, and played the complete sixty-objective diplomatic route to the finale. Both routes returned `CAMPAIGN ROUTE RESULT: PASS quests=60 days=8`; the logs are shipped beside the frames. The public pack cannot be scripted by design — its verifier is physically excluded — so these frames are the closest record of what a player sees from shipping code.

## Check by check

| Owner check | Executed evidence | Inspected here | What still needs a person |
|---|---|---|---|
| 1. Second Oath, Peace refusal, banner in finale/save list/credits, Third Oath | `tests/test_second_oath.gd`, `tests/test_campaign_finale.gd`, `tests/test_oath_migration.gd` (both locales); three native victories on the exported QA pack; both complete routes; both capture runs below | `owner-checks/en-qa.png`, `ru-qa.png`: the real finale reports 60/60 objectives, the Banner of Victory, the earned titles and both actions with "Take the Second Oath" focused; `en-oath-panel.png` / `ru-oath-panel.png`: the panel lists all four oaths with their effects and the carried titles; `en-oath-panel-peace.png`: the Peace oath selected; `en-peace-refusal.png` / `ru-peace-refusal.png`: a refused siege raises the localized warning toast ("The Oath of Peace forbids sieges" / "Клятва мира запрещает осады"); `en-title-carried-oath.png` / `ru-title-carried-oath.png`: the title screen prints the carried cycle, banner and titles | Play one full cycle by hand, refuse a siege under the Peace oath in your own language, and start a Third Oath with a different modifier |
| 2. Codex unlocks from play, locked entries stay locked, state survives a reload | `tests/test_codex.gd` (25 entries, event unlocks), `tests/test_oath_migration.gd` (codex progress survives migration) | `docs/galleries/1.6.0/ru-1280x720-codex.png` and the EN twin: localized tabs, "Найдено: 2 из 25", locked rows shown as "???", readable entry body | Unlock three entries while playing naturally and reload a save once |
| 3. Tracker on every surface, both languages, removed together | `tests/test_quest_tracker.gd`, `tests/test_navigation_matrix.gd` | `owner-checks/en-qa-village.png`: HUD objective panel, speaker line, measured distance (463 m) and compass over bright weather; `en-qa-map.png` / `ru-qa-map.png`: atlas with the objective marker and a legend that names all five marker types in both languages; `en-qa-journey.png`: the town panel with localized tabs and icons | Walk one objective with the keyboard only and end the campaign to see all five surfaces disappear at once |
| 4. Feel by ear and eye | `tests/test_combat_feel.gd` asserts the freeze (`time_scale` 0.05), real-time release inside the authored window, the seven-shard spark, distinct swing/flesh cues, the struck enemy's health, and a floating damage number with a font of at least 23 px; `tests/test_comfort_preferences.gd` asserts reduced motion removes the freeze | `scripts/autoload/SettingsManager.gd`: default hit-stop 75 ms, clamped to 60–90 ms; `scripts/ui/HUD.gd`: heavy hits (≥ 25% of max health) use 28 px and brass `#C9A227`, others 23 px and parchment `#E8DCC3`, both with a 2 px black shadow | Listen to the mix and judge whether the hit-stop reads as a beat; see below for the measured pickup-chime level |
| 5. Grow a town, load an old profile | `tests/test_settlement_evolution.gd` (tiers at 1/6/15/25 built levels, upgrade cue, seasonal tint); `acceptance-1.6.0/legacy.json` (real 1.1 fixtures and protected 1.4.0/1.5.0 saves, four executed cases across both locales, two per locale) | `docs/galleries/1.6.0/en-1280x720-settlement.png`: tier badge, ten building tiles with three pips each, semantic meters; `village-rain.png` for weather; `settlement-tier2.png` and `settlement-tier3.png` in both locales: the same hearth with six and fifteen built levels (the system reports tier 2 and tier 3) — the hall and its banner appear at tier 3 where tier 2 shows open ground | Raise a settlement to tier 2 and 3 while watching the skyline, and load a 1.4.0/1.5.0 profile once, keeping the backup |

## Captured after publication

The frames added after the first pass come from a QA-only capture script that drove shipping code directly: it set the campaign state, opened the real OathPanel, triggered a refused `start_assault`, staged the title screen from a saved campaign and rebuilt the home settlement to six and fifteen levels before rendering with the real Compatibility renderer at 1280×720. Every screen was produced in RU and EN. Two things are worth recording as measurements rather than impressions:

- The primary action label in the oath panel measures `#DFDFDF` on a `#151718` bar, a contrast ratio of 13.5:1, so the dark bar is a style choice and not a legibility problem.
- The growth pair is the same camera and the same hearth: at tier 2 the ground behind the palisade is empty, at tier 3 the hall and its banner are standing. Nothing else in the frame changed.

## Measured audio levels behind the pickup-chime check

The earlier wording of check 4 claimed the rare pickup chime is quieter than the music bed. That claim was not measured, so it was measured now:

| File | Length | Peak | RMS |
|---|---|---|---|
| `loot_chime.wav` | 0.46 s | −2.2 dBFS | −12.6 dBFS |
| `stone_path_to_dusk.wav` | 117.3 s | −8.5 dBFS | −22.4 dBFS |
| `hearths_among_the_hills.wav` | 124.0 s | −7.3 dBFS | −23.7 dBFS |
| `steel_and_rain.wav` | 124.0 s | −11.0 dBFS | −23.7 dBFS |
| `standards_at_dawn.wav` | 124.0 s | −8.1 dBFS | −23.7 dBFS |
| `oaths_remembered.wav` | 20.0 s | −8.2 dBFS | −23.7 dBFS |
| `the_last_watch.wav` | 20.0 s | −7.1 dBFS | −24.8 dBFS |

In the engine the chime plays as a spatial cue on `SFX_Environment` with a fixed −6 dB player gain, a 3 m unit size and a 38 m maximum distance (`scripts/audio/AudioDirector.gd`), so at arm's length it arrives around −18.6 dBFS RMS against music that sits near −23 dBFS RMS at 0 dB on the Music bus. In plain terms: **the chime is a short, bright cue that is louder than the bed while it rings, not quieter.** The documentation was corrected rather than the mix, because this is a listening decision, not a defect: the owner check is now "confirm the chime reads as a pickup and does not mask the music", and the numbers above are the starting point for that judgement. The music bus has its own slider, so a player who prefers a quieter effect can lower effects without losing the soundtrack.

## What this record does not claim

It does not replace playing, listening or judging. It removes guesswork about mechanics, localization and what the frames contain, and it records one documentation claim that measurement did not support. The release assets published on GitHub are unchanged by this record.
