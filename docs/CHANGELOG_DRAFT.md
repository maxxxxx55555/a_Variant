# CHANGELOG — v2 integration draft

- Reconciled archived promises against the compact edition, with explicit exclusions and a complete original-line registry.
- Removed mixed historical design scope; new negative guard tests catch copied design/runtime references.
- Added branded boot/loading hints and explicit retry/stay/discard handling after a failed exit save.
- Added contextual disabled explanations and retained real transaction prices in tooltips.
- Publication stayed locked through the v2 phases until each section had its own evidence; the release gate that lifted it is recorded per edition, and the live gate status belongs to [the acceptance certificate](ACCEPTANCE_CERTIFICATE.md), not to this draft.
- Mouse sensitivity and live MSAA quality are accessible and persistent; long settings scroll. Escape returns through settings; paused menus freeze the background music, while ending stingers complete. Finale state is autosaved.

- F2: audited literal keys and blank scene defaults; verified both locale catalogs and actual typeface glyphs.
- Fixed misleading alchemy feedback: a missing ingredient now says “missing” instead of red “OK”; units/help use localization keys.
- Live locale switching now refreshes home/town/companion/gate world labels and preserves the selected inventory item and alchemy recipe; a real-world regression reproduced four failures before the fix.

F3: published art tokens and individual79-file source review; fixed clipped icon corners; refined meadow silhouettes, added110 off-road landmarks in102 spatial batches and matched the actual road geometry on the atlas; keyboard map selection/activation and a live localized legend; concise menu briefing. Source gallery and final gate evidence are tracked separately.

Rendered F3 review reproduced a first-frame T-pose when distant characters were culled before AnimationPlayer first evaluated. DetailedFigure now applies its idle pose immediately. test_initial_idle_pose.gd covers armed/unarmed figures and the real distance-culling path; full-suite rerun follows the fix.

F3 settings review found that the old Back action started clipped below the scroll content and did not restore focus. A permanent header/back action and larger token-aligned settings card now preserve escape at either scroll end; test_settings_navigation.gd reproduces the original behavior and checks the fix. Ground uses the retained curated meadow texture with restrained cobble tint; map text has a backing outline against route lines.

The gait review found that fleeing residents and fast followers reused an unscaled walk. Existing licensed jog/sprint clips now match actual horizontal motion, idle resets its pace and attack timing is independent of the previous gait. test_locomotion_gait.gd reproduces the resident issue through its real movement path.

V2 F4: preserve the four distinct recorded mood tracks and two finales; add quiet focus/unavailable synthesis with honest CC0 hashes, one contextual acknowledgment per action, restrained cosmetic pitch variation and real rejected-action regressions. QA remains muted.

## F5 — integrity integration, awaiting final gate

Separate encrypted public/private QA exports and environment-only keys; physically excluded public verifier. Compiled critical-data manifest/trusted fallback and localized read-only safe mode. Localized authenticated-save recovery and stable unchanged round trips. New regression tests cover replacement manifests, safe-mode write/deletion boundaries, key preflight, public flags and save recovery.
Resource credit bounds and transaction/save-load reentry protection, with negative/nonfinite/cap/stack and craft/trade round-trip regressions.

## 1.6.0 — Second Oath & Polish

- Second Oath (New Game+): four authored oath modifiers, roster/gear/titles/difficulty carry, per-cycle enemy scaling, and an oath banner stored in the save and printed on the finale, save-slot list and credits.
- World Codex (25 entries, four categories) unlocking from real campaign events; quest tracker binding HUD objective, measured distance, compass, map marker and toasts to one target; combat and loot game-feel passes; settlement tiers derived from real built levels with a seasonal terrain tint; local per-profile statistics page.
- Design pass over palette, typography, the 46-icon set, motion and reduced motion, with 56 rendered gallery frames (14 screens × 2 locales × 2 viewports).
- Reproducible bytes: Windows tool writers now emit the committed LF bytes, so the critical-data manifest, compiled trust anchor and interface SFX provenance agree with a plain Git checkout on any platform.
- Executed mechanics evidence: `tests/test_mechanics_route.gd` runs `tests/MechanicsRoute.gd`, `tools/collect_mechanics_evidence.py` executes every matrix reference in both locales, and `tools/static_census.py` replaces hand-counted orphan/dead-code claims.
- Defects found by that execution and fixed before release: the finale left no control focused when the Second Oath was unavailable, the tracker relocalization test assumed the launch locale was Russian, and seeded fuzz reported the authored plain (zero-modifier) Second Oath as lost state.
- Full notes: [RELEASE_1.6.0.md](RELEASE_1.6.0.md).

## 1.6.1 — legacy save import needs a person

A security review of 1.6.0 found that a checksum-only v1–v3 profile was applied silently and re-signed as an
authenticated v4 save, so forging that one path never needed the installation key. The compatibility path stays, but it
is no longer silent: the loader now refuses such a file, records it as pending, and the game asks once — in the active
language, with localized Import / Do not import actions — whether that slot's old profile should be imported.
Confirming applies it and re-signs it under schema 4 with the per-slot lock; declining leaves the file byte-identical
and applies nothing. The existing per-slot guard still refuses a checksum-only file wherever authenticated progress
already exists. Four localization keys were added (810 per locale) and `tests/test_legacy_import.gd` asserts the whole
exchange in both languages, including that a refusal changes no bytes.
