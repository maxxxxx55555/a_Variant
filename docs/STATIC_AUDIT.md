# Static shipping audit

Orphan .uid/.import sidecars:0. Unused literal assets after glTF dependency resolution:0. Shipping TODO/FIXME/placeholder/lorem markers:0. Non-engine function candidates without references:0.

Native callbacks retained:
- `scripts/security/BuildIntegrity.gd::_enter_tree`: Godot Node lifecycle override, first-autoload trust validation.
- `scripts/world/AdultProportions.gd::_process_modification`: Godot SkeletonModifier3D virtual: adult proportion adjustment.

The graph includes scripts, scenes, resources, project autoloads, tests and relative glTF buffer/image dependencies. Identifiers found only once are reviewed explicitly above. Dynamic engine hooks are retained; unreferenced application helper methods were removed. This census complements strict compilation and runtime suites and does not establish proof of every possible execution.

CI: `.github/workflows/shipping-warnings.yml` imports the project and invokes the same49-category strict audit on main pushes and pull requests, using a pinned checkout commit and SHA256-verified Godot4.7 download. Local and hosted execution pass: 89 shipping scripts,49 warning categories on the verified Godot4.7 Ubuntu24.04 runner. Hosted evidence: https://github.com/maxxxxx55555/a_Variant/actions/runs/40284405013 at `fadde7735e41658432007fee5dedc636050a095c`. The final release HEAD must also receive its own hosted run.

## Marchland Oaths 1.6.0 census

The census is now machine-generated instead of hand-counted:

```bash
python tools/static_census.py   # sidecars, unreferenced sources, dev markers, dead shipping functions
```

Result on the 1.6.0 candidate: orphan sidecars 0, unreferenced sources 0, development markers 0,
unreferenced shipping functions 0, inventory 105 shipping scripts and 83 test scripts. The tool
resolves glTF buffer and image dependencies before counting and matches sources by full path, file
name or bare stem, because `scripts/ui/IconSet.gd` composes icon paths from `IconSet.NAMES`.
`tests/run_tests.py` runs the census as a release-gate contract, so a new orphan file fails the suite.

Two findings were closed rather than documented as acceptable:

- `scripts/autoload/ProfileStats.gd::capture_profile` and `restore_profile` had no shipping caller;
  the profile save path uses each autoload's own state methods. The pair was deleted and
  `tests/test_oath_migration.gd` now restores statistics through `restore_state`.
- `tests/MechanicsRoute.gd` asserted terminal campaign rules but no runner loaded it, so the
  mechanics matrix cited a source that never executed. `tests/test_mechanics_route.gd` now runs it
  and `tests/run_tests.py` registers the case with the other full-campaign routes; the executed run
  reports `CAMPAIGN ROUTE RESULT: PASS route=diplomatic quests=60` with `mechanics_contract=PASS`.

Strict compilation remains `STRICT SHIPPING COMPILE PASS 105 scripts 49 categories`, and the hosted
49-category audit on `.github/workflows/shipping-warnings.yml` must report green for the release HEAD.
