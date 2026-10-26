# Localization source audit — v2 F2

Catalog: 675 keys in each of RU and EN. Both editable CSV files contain identical keyed rows. Compilation validates nonempty values and placeholder parity. The source audit rejects missing literal keys, unkeyed Cyrillic model/UI copy and nonempty hardcoded scene labels. Blank scene controls are populated by localized _ready handlers before display. Native language names remain readable regardless of the active language. English product brands and standard input symbols are deliberate identifiers.

First launch suggests the system language, offers an explicit selector and persists confirmation. Live switching preserves the existing scene and gameplay state. Body/heading fonts are checked for Cyrillic, ё, punctuation and currency symbols. Decorative legacy emoji are preserved in canonical Russian content but omitted by the concise presentation layer; this avoids relying on an OS color-emoji font.

All remaining model copy uses existing catalog keys; no saved event IDs, event ordering or schema changes are part of this extraction. QA route title matching is nonvisible diagnostic code; its public-build exclusion is an independent F5 requirement.

The F1 suite inventory was corrected from an inherited estimate: actual executed case logs are authoritative. Current default source case count: 36. Final v2 protocol evidence is generated after all later phases.

Found and fixed: unavailable alchemy ingredients were labelled red “OK”. test_localized_feedback.gd reproduces the bug, then checks “missing/не хватает” and “ready/готово”. Units and the compact help cue now have keys. Original shipped locale rows were retained.

A further real-world live-switch regression exposed stale 3D labels and cleared inventory/recipe selection. MarchWorldLabel binds localization to node lifetime; the existing rendered world and inventory stay intact. test_live_world_locale.gd checks the actual labels, selected controls and unchanged gameplay state.
