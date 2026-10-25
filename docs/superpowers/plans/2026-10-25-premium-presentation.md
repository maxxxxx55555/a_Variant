# Premium Presentation Implementation Plan

**Goal:** Deliver a substantial, verified art/interface upgrade to both existing playable games.
**Architecture:** Central game-specific theme/type tokens, scalable native button art, a bounded finance portrait renderer, and a cached modular RPG figure layer replace presentation without owning gameplay or save data.
**Tech Stack:** Godot 4.7, GDScript, licensed glTF/PNG/OFL fonts; Python for asset provenance/build/QA orchestration.

## Global constraints
- Autonomous inline execution; no subagents, no new approval flow.
- Existing mechanics, distinct music, profiles and collision footprints remain compatible.
- No AAA-budget, exact reference, zero-bug or unbreakable-security claim.
- All tests silent, user-facing outputs under outputs/release-1.3.0, previous releases untouched.

## Task 1 — Type and controls
Files: scripts/ui/*Theme.gd; assets/fonts; assets/ui; tests/test_premium_ui.gd in both repositories.
- [ ] Write real theme/layout/focus/Cyrillic assertions and observe missing new surfaces/fonts.
- [ ] Install OFL fonts with source/notice digests. Create scalable native button normal/hover/pressed/disabled/focus surfaces; replace all legacy font overrides and inconsistent defaults.
- [ ] Render real menus and long-choice screens, adjust measured layout and contrast, verify native input/focus and save warnings.

## Task 2 — Finance character/art
Files: scripts/ui/FortuneDashboard.gd; assets/art/life-portraits.png; tests/test_premium_ui.gd.
- [ ] Assert age-to-portrait selection changes without changing game state.
- [ ] Generate one clearly fictional life-stage portrait atlas, integrate into the actual dashboard with measured balance/type spacing.
- [ ] Check dense late-game balances, endings and 360/540-width portrait layouts in real renders.

## Task 3 — RPG figures and atmosphere
Files: scripts/world/MarchAssets.gd, MarchArt.gd, new figure controller; assets/art/humans; tests/test_detailed_figures.gd.
- [ ] Verify licensed source downloads and inspect actual skeletons/animation tracks before integration.
- [ ] Fail a real rig test on the previous low-detail character; import bounded modular meshes, bind heads/hair/clothes and shared idle/walk animation; retain weapons/visibility and gameplay ownership.
- [ ] Render close-ups, walk/idle and armed/unarmed variants; check creation/destruction lifetime and performance with real world actors.
- [ ] Refine playable environment framing/atmosphere only where captures show a concrete visual improvement.

## Task 4 — Release QA
- [ ] Run focused tests then complete source suites, fixing reproduced regressions with regression tests.
- [ ] Export new Windows builds, traverse both 60-objective routes and financial win/loss; verify screenshots and benchmark actual rendering.
- [ ] Export Android preview; verify exact APK signatures, actual touch, lifecycle, protected upgrade/recovery and endings on owned emulator.
- [ ] Publish immutable versioned builds/source/credits/captures, merge exact tested trees and verify public hashes/archive bytes. Record remaining limits accurately.
