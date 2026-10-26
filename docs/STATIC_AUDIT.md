# Static shipping audit

Orphan .uid/.import sidecars:0. Unused literal assets after glTF dependency resolution:0. Shipping TODO/FIXME/placeholder/lorem markers:0. Non-engine function candidates without references:0.

Native callbacks retained:
- `scripts/security/BuildIntegrity.gd::_enter_tree`: Godot Node lifecycle override, first-autoload trust validation.
- `scripts/world/AdultProportions.gd::_process_modification`: Godot SkeletonModifier3D virtual: adult proportion adjustment.

The graph includes scripts, scenes, resources, project autoloads, tests and relative glTF buffer/image dependencies. Identifiers found only once are reviewed explicitly above. Dynamic engine hooks are retained; unreferenced application helper methods were removed. This census complements strict compilation and runtime suites and does not establish proof of every possible execution.

CI: `.github/workflows/shipping-warnings.yml` imports the project and invokes the same49-category strict audit on main pushes and pull requests, using a pinned checkout commit and SHA256-verified Godot4.7 download. Local and hosted execution pass: 89 shipping scripts,49 warning categories on the verified Godot4.7 Ubuntu24.04 runner. Hosted evidence: https://github.com/maxxxxx55555/a_Variant/actions/runs/40284405013 at `fadde7735e41658432007fee5dedc636050a095c`. The final release HEAD must also receive its own hosted run.
