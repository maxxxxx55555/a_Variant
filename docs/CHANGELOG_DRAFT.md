# CHANGELOG — v2 integration draft

- Reconciled archived promises against the compact edition, with explicit exclusions and a complete original-line registry.
- Removed mixed historical design scope; new negative guard tests catch copied design/runtime references.
- Added branded boot/loading hints and explicit retry/stay/discard handling after a failed exit save.
- Added contextual disabled explanations and retained real transaction prices in tooltips.
- Publication remains locked until all v2 phase evidence and the final gate pass.
- Mouse sensitivity and live MSAA quality are accessible and persistent; long settings scroll. Escape returns through settings; paused menus freeze the background music, while ending stingers complete. Finale state is autosaved.

- F2: audited literal keys and blank scene defaults; verified both locale catalogs and actual typeface glyphs.
- Fixed misleading alchemy feedback: a missing ingredient now says “missing” instead of red “OK”; units/help use localization keys.
- Live locale switching now refreshes home/town/companion/gate world labels and preserves the selected inventory item and alchemy recipe; a real-world regression reproduced four failures before the fix.

F3: published art tokens and individual79-file source review; fixed clipped icon corners; refined meadow silhouettes, added110 off-road landmarks in102 spatial batches and matched the actual road geometry on the atlas; keyboard map selection/activation and a live localized legend; concise menu briefing. Source gallery and final gate evidence are tracked separately.

Rendered F3 review reproduced a first-frame T-pose when distant characters were culled before AnimationPlayer first evaluated. DetailedFigure now applies its idle pose immediately. test_initial_idle_pose.gd covers armed/unarmed figures and the real distance-culling path; full-suite rerun follows the fix.

F3 settings review found that the old Back action started clipped below the scroll content and did not restore focus. A permanent header/back action and larger token-aligned settings card now preserve escape at either scroll end; test_settings_navigation.gd reproduces the original behavior and checks the fix. Ground uses the retained curated meadow texture with restrained cobble tint; map text has a backing outline against route lines.

The gait review found that fleeing residents and fast followers reused an unscaled walk. Existing licensed jog/sprint clips now match actual horizontal motion, idle resets its pace and attack timing is independent of the previous gait. test_locomotion_gait.gd reproduces the resident issue through its real movement path.
