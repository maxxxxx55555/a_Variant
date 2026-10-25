# Clear Play Implementation Plan

**Goal:** Reduce interface reading and improve actual action/control presentation in both playable games.
**Architecture:** Finance ChoiceCopy/ChoiceCard own presentation only; Main owns real events and short notices. RPG TownMenu owns three tab pages while existing action callbacks and fields remain stable. Shared native themes own rounded scalable surfaces; project viewport owns2xMSAA.
**Tech Stack:** Godot4.7, GDScript, original SVG, existing licensed fonts/figures/PBR; Python build/QA orchestration.

## Global constraints
- Autonomous inline execution; no subagents. Existing approved style, money/RNG/combat/saves/music remain compatible.
- Previous releases immutable; outputs/release-1.4.0 only user deliverables; silent QA.
- Costs/risks/requirements stay visible; optional instructions are available on demand; no arbitrary ellipsis of decision effects.
- English progress and exactly two short English final lines; no perfect/AAA guarantee.

## Task1 — Finance action cards and concise event
Files: scripts/ui/ChoiceCopy.gd, ChoiceCard.gd; scripts/Main.gd; tests/test_clear_play.gd.
- [ ] Add a real-scene test that selects known event labels, asserts compact title/separate cost+chance, focuses/clicks the original Button and checks exactly one ordinary turn.
- [ ] Run `work/run_godot.py game_for_day clarity-red --headless --script res://tests/test_clear_play.gd`; observe missing card labels/notice.
- [ ] Implement `ChoiceCopy.parts(raw:String)->Dictionary` and native Button view, preserving raw full text and callbacks. Separate outcome notice from current event; shorten intro/market/business labels.
- [ ] Run focused test with real GPU at540x960 and360x800; inspect bounds, all effects, save restoration and captures. Commit with real evidence.

## Task2 — RPG focused town and quiet HUD
Files: scripts/ui/TownMenu.gd, HUD.gd; data/strings/ru.csv,en.csv; scripts/verification/CampaignRoute.gd; tests/test_clear_play.gd.
- [ ] Test actual town open, three focused pages, visible default journey/report, select Trade and use a real resource button, select Siege and assert reachable real controls; expand help and assert original cost/instructions remain accessible in both languages.
- [ ] Observe RED on existing monolithic town menu; implement tab pages, concise localized labels/tooltips and help disclosure with stable callback fields.
- [ ] Navigate actual pages in campaign route harness before real input; run focused UI/mechanics tests and render town/HUD.

## Task3 — Surfaces and real-time visual clarity
Files: assets/ui/button-*.svg, scripts/ui/*Theme.gd, a_Variant/project.godot.
- [ ] Replace only authored SVG surface geometry with smooth rounded surfaces, consistent margins/states/focus; keep existing font families.
- [ ] Set viewport2xMSAA using engine setting `rendering/anti_aliasing/quality/msaa_3d=1`; render the real rainy world and compare load/FPS/edges. Retain only with acceptable measured play (~45FPS or better on current fixture).
- [ ] Complete both source suites after final production changes; fix only reproduced failures and rerun affected checks.

## Task4 — New release
- [ ] Version1.4.0/code140, truthful README/notes; commit exact final source; export Windows/Android.
- [ ] Both real native RPG routes60/60 and finance win154/defeat10, Android1.3->1.4 protected upgrade and real controls/FX/lifecycle/recovery/entrypoint/defeat.
- [ ] Capture new actual gallery with tab pages/action cards, preserve all notices/provenance; publish new immutable releases/PRs and merge only tested trees.
- [ ] Independently verify every source ZIP Git blob, public hashes, archive CRC, screenshot hashes and all final logs; stop owned emulator and record remaining limits.
