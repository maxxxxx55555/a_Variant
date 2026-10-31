# Localization source audit — v2 F2

Catalog: 675 keys in each of RU and EN. Both editable CSV files contain identical keyed rows. Compilation validates nonempty values and placeholder parity. The source audit rejects missing literal keys, unkeyed Cyrillic model/UI copy and nonempty hardcoded scene labels. Blank scene controls are populated by localized _ready handlers before display. Native language names remain readable regardless of the active language. English product brands and standard input symbols are deliberate identifiers.

First launch suggests the system language, offers an explicit selector and persists confirmation. Live switching preserves the existing scene and gameplay state. Body/heading fonts are checked for Cyrillic, ё, punctuation and currency symbols. Decorative legacy emoji are preserved in canonical Russian content but omitted by the concise presentation layer; this avoids relying on an OS color-emoji font.

All remaining model copy uses existing catalog keys; no saved event IDs, event ordering or schema changes are part of this extraction. QA route title matching is nonvisible diagnostic code; its public-build exclusion is an independent F5 requirement.

The F1 suite inventory was corrected from an inherited estimate: actual executed case logs are authoritative. F2 default source case count: 36. Final v2 protocol evidence is generated after all later phases.

Found and fixed: unavailable alchemy ingredients were labelled red “OK”. test_localized_feedback.gd reproduces the bug, then checks “missing/не хватает” and “ready/готово”. Units and the compact help cue now have keys. Original shipped locale rows were retained.

A further real-world live-switch regression exposed stale 3D labels and cleared inventory/recipe selection. MarchWorldLabel binds localization to node lifetime; the existing rendered world and inventory stay intact. test_live_world_locale.gd checks the actual labels, selected controls and unchanged gameplay state.

F3 adds 5 keyed labels/briefing entries; current catalog count is680 per language. The rendered suite now has41 cases (headless has40; full campaign adds2). F2 historical evidence above is unchanged.

F4 adds two non-copy audio regression cases; current runner count is43 rendered /42 headless; full campaign adds2. Localization keys remain unchanged from F3.

F5 adds five keyed integrity/recovery captions: 685 keys and49 rendered /48 headless cases (full campaign adds2) in the current source. Earlier phase counts above are historical. Full F5 bilingual logs and native pack checks are recorded separately from final F7 acceptance.

F6 adds two terminal recovery explanations:687 keys per language. Iron death keeps a short terminal label and its full translated reason during live language changes; normal death retains paid recovery. Current source runner inventory:62 rendered invocations including import; optional complete campaign pair adds2. These are inventory counts; final execution hashes remain in the release evidence.

## Marchland Oaths 1.6.0 — Second Oath & Polish

Catalog: 810 keys in each of RU and EN. 119 keyed entries were added for 1.6.0 and none were removed, so every 1.5.x string still resolves; 1.6.1 adds four more for the legacy-import confirmation (title, body, accept, decline). The additions are grouped as codex 44, oath 28, stats 12, settlement 7, escalation 6, objective 5, ui 4, flow 3, ending 2, menu 2, tutorial 2 and hud, map, siege and credits 1 each.

`tests/test_verification.py` proves the two CSV files hold the identical key set, that each compiled entry in `data/balance/localization.json` equals its RU and EN source row, and that placeholder sets match per key. `tests/test_localization.gd` repeats the same checks against the compiled catalog the shipping build actually reads and rejects duplicate or empty keys. `tools/compile_localization.py` regenerates the compiled catalog; `tools/build_manifest.py` then re-signs it into `scripts/security/TrustedData.gd`, because the runtime reads critical data from the embedded snapshot rather than from disk.

Every new surface was audited in both languages at both viewports rather than inferred from the catalog: `tests/capture_gallery.gd` renders 14 screens per locale at 1280×720 and 1920×1080 — 56 frames in `docs/galleries/1.6.0/` — and `docs/GALLERY_ACCEPTANCE_1.6.0.md` records the review. The rendered pass caught four real presentation defects — raw node names in Codex tabs, an unlabeled Codex close button, healthy settlement meters painted in danger red and a diplomacy list that clipped two of eight factions — all fixed in shipping code and recaptured.

Feature copy is keyed, not literal: `tests/test_codex.gd` requires real Russian *and* English prose for all 25 lore entries, `tests/test_stats.gd`, `tests/test_quest_tracker.gd` and `tests/test_settlement_evolution.gd` each switch the live language mid-test and re-assert their labels, and `tests/test_oath_migration.gd` shows that a pre-1.6 profile gains the oath fields without losing any translated state. Native oath and title names stay readable in both locales.
