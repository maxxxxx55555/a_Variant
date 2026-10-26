# F6 regression work

The source runner passes51 Godot cases in each of English and Russian after the additions below. This is an intermediate source checkpoint; the full v2 release gate remains open.

- `tests/test_navigation_matrix.gd`:26 actual menu/tab states, keyboard focus and Escape including number-editor cancellation, live locale and resize.
- `tests/test_qa_seed.gd`: private/source route seed parsing rejects empty-invalid, negative, zero and overflowing seeds while retaining the deterministic default.
- `tests/soak_gameplay.gd` / `tests/SoakRoute.gd`: real60-quest campaign loops with ordinary settings, save/reload and locale checkpoints, measured using wall time. These drivers are excluded from public exports.
- `tests/fixtures/protected-v1.4.0-autosave.json`: byte-identical original1.4 protected profile, with provenance. Its installation key is retained privately for compatibility testing and is never included in source or release assets.

Preliminary live soak:3 complete diplomatic campaigns,21UI/save/locale checkpoints,2606.863seconds of gameplay; no script errors. Raw process CPU/memory data are retained in the release evidence. Allocation variation is measured, not described as exactly zero. Final frozen-source fuzz, strict compiler checks, mechanics matrix and F7 acceptance remain pending.

## Exact floating-point profile restoration

The native decimal parser can round a valid double by a few ULPs. `test_profile_contract.gd` exposed this during complete-state restoration; `test_save_float_precision.gd` use byte-constructed doubles and full-precision hashes. Current authenticated envelopes add bounded exact float patches inside the signed body. Restoration is atomic, accepts only existing numeric leaves and parser-sized differences, and uses no object deserialization. Schema4 and previous protected profiles remain supported. `test_exact_float_limits.gd` rejects malformed, duplicate, nonfinite and oversized patches without mutation.

The full source runner now imports first, then compiles every shipping GDScript with all49 warning categories promoted to errors before gameplay tests. It restores project.godot bytes even on failure. External QA drivers are checked separately by the gameplay suite.

## Invalid combat input and terminal callback

`test_invalid_combat_inputs.gd` reproduced negative/nonfinite hits healing or corrupting player/enemy health and equipment wear. Damage and wear now reject those values before stamina, health or durability changes; enemy death is idempotent. Invalid weather enum values are rejected.

## Recruited soldiers continuing behind pause

`test_army_pause_regression.gd` reproduced real recruited actors inheriting the world menu owner's always-running process mode. SoldierActor explicitly uses PAUSABLE; the test checks frozen positions while paused and normal movement after resume. `test_profile_contract.gd` also checks the entire campaign hash across pause, live language changes and a real pause-menu save/reload.

## Checked packed-array operations

Godot packed-array append returns an error flag: false means success. The strict typing pass retains geometry and text construction by checking that flag in the correct direction. `test_packed_append_regression.gd` inspects terrain, physical mesh, road connections and workshop cost text.

## Catalog authority for exploration rewards

`test_untrusted_exploration.gd` reproduced fabricated IDs granting supplies, camp-kind substitution bypassing combat, and reward overflow making a profile unsaveable. Exploration now resolves IDs against the shipped catalog, uses authoritative kind/faction data and checks every credited resource before changing progress. Ordinary landmarks still reward once; twenty repeat activations cannot duplicate them.

`test_mechanics_inputs.gd` adds real rapid-input and boundary coverage for the edition systems; it does not grant resources in the full-cycle release verifier. Large boundary fixtures in this isolated test intentionally exercise caps and rejection.

The hardening driver mutates1855 fields in two original profiles. A quiet run takes about90seconds on this host; running several complete 3D worlds concurrently exceeded its180second harness deadline. Its bounded exhaustive mutation case now has a600second deadline, with phase progress retained. Assertions and the number of mutations are unchanged. This is test resource contention, not an accepted gameplay hang.

## Companion actor duplication from strict-cleanup indentation

The compiler-cleanup candidate incorrectly dedented tracked-handle removal outside the obsolete-companion condition. Repeated scans therefore spawned untracked allies; accelerated full routes became progressively slower. Native script profiling identified CompanionActor consuming77% of a sampled frame with508 calls versus4 player calls. `test_companion_scan_regression.gd` reproduces the bug with25 scans and checks one tracked/live/saved actor, pause/live locale/hash restoration and complete removal. The indentation is corrected. All matching old/new unique statements were checked for indentation drift; this was the sole mismatch. Earlier affected route timeouts and the incomplete soak are rejected evidence; the complete source suites,50routes and soak are rerun.

## Freed soldier reference in typed roster filtering

The extended military route completed60 objectives but its clean-log gate caught a callback conversion error after a soldier was freed. A typed filter argument is converted before its validity predicate executes. `test_army_casualty_lifetime.gd` reproduces a genuinely destroyed actor and a disband cleanup; the original refresh failed both checks. Reverse-index pruning now validates the reference before reading it as a SoldierActor. Focused regression and all49 strict warning categories pass. Earlier affected route/soak evidence is rejected; complete suites,50 routes and measured soak are rerun against the corrected source.

## Iron death callback reentry and live terminal copy

`test_iron_death_reentry.gd` reproduced repeat death events, blocking-stamina consumption after death, and direct resume/restart callbacks reviving an iron character despite its disabled button. Live locale changes also replaced the terminal message with a respawn label and left disabled actions unexplained. Damage now stops at a terminal player, and both the menu callback and world recovery method enforce iron mode. The short terminal label and full reason follow EN/RU; ordinary paid recovery remains available. The test exercises20 late hits,20 repeated load/resume/restart calls, unchanged authenticated tombstone bytes, live languages, Escape and an actual return to title. RED10 failures, GREEN clean. Full source suites,50 seeded routes and measured soak are restarted against this final version; earlier normal-route evidence is retained as historical, not substituted.

The complete suite exposed an obsolete gameplay fixture which assigned zero health before asking damage to dispatch death. The terminal guard correctly ignored that already-dead target. The fixture now starts alive at1HP and applies a real lethal hit, additionally asserting zero health; its recovery-screen and20% gold/equipment penalty checks are unchanged. No production behavior was relaxed.

## Private native iron-death acceptance entry

The Windows input backend cannot hold movement keys and this release template does not run external SceneTree scripts. A named native iron-entry test first reproduced the missing private --defeat route (it ran the ordinary campaign instead). The compile/env-gated verifier now has an internal iron-death acceptance route, excluded with every verification script from public exports. It applies controlled lethal damage, checks20 repeated damage/recovery callbacks, EN/RU terminal reasons, unchanged authenticated tombstone bytes, Escape, real return-to-title and ordinary20% recovery. It does not alter public game code or ordinary victory routing. Completed simulation/soak evidence remains applicable to those identical ordinary paths; the private build receives fresh strict/source/native acceptance.

## Portable promise and inherited-license byte contracts

A fresh Git checkout normalized the promise documents while their inventory recorded Windows line endings. Explicit LF rules and unchanged verbatim lines now make those digests portable. The pre-release README inventory is retained in its own immutable snapshot where needed. Protected profile fixtures, creator licenses and provenance use opaque Git attributes. The inherited-license test derives its expected bytes from the original published1.4.0 Windows archive. All14 inherited license files were already byte-correct; their Git round-trip is now protected.
