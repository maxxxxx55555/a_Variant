# F6 regression work

The source runner passes51 Godot cases in each of English and Russian after the additions below. This is an intermediate source checkpoint; the full v2 release gate remains open.

- `tests/test_navigation_matrix.gd`:26 actual menu/tab states, keyboard focus and Escape including number-editor cancellation, live locale and resize.
- `tests/test_qa_seed.gd`: private/source route seed parsing rejects empty-invalid, negative, zero and overflowing seeds while retaining the deterministic default.
- `tests/soak_gameplay.gd` / `tests/SoakRoute.gd`: real60-quest campaign loops with ordinary settings, save/reload and locale checkpoints, measured using wall time. These drivers are excluded from public exports.
- `tests/fixtures/protected-v1.4.0-autosave.json`: byte-identical original1.4 protected profile, with provenance. Its installation key is retained privately for compatibility testing and is never included in source or release assets.

Preliminary live soak:3 complete diplomatic campaigns,21UI/save/locale checkpoints,2606.863seconds of gameplay; no script errors. Raw process CPU/memory data are retained in the release evidence. Allocation variation is measured, not described as exactly zero. Final frozen-source fuzz, strict compiler checks, mechanics matrix and F7 acceptance remain pending.
