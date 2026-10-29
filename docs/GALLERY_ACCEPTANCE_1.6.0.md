# Gallery acceptance — Marchland Oaths 1.6.0

The 1.6.0 rendered gallery lives in `docs/galleries/1.6.0/`. Every image is a real frame from `tests/capture_gallery.gd` running against the shipping project, not a mockup. The set covers both locales, RU and EN, at both release viewports, 1280×720 and 1920×1080.

## Capture matrix

- 1280×720: windowed, `--resolution 1280x720`, Compatibility renderer, Dummy audio driver, isolated save profile.
- 1920×1080: fullscreen, `--resolution 1920x1080`, the same renderer and profile isolation. Fullscreen is required because a decorated 1920-wide window is clamped to 1920×1055 by the desktop work area.
- Locales: RU and EN, set with `GAME_LANGUAGE` before the title screen is instantiated.
- Files are named `<locale>-<width>x<height>-<screen>.png`.
- Capture command shape: `godot --rendering-method gl_compatibility --path . [--fullscreen] --resolution <WxH> --script res://tests/capture_gallery.gd` with `GAME_GALLERY_DIR` and an isolated `APPDATA`/`LOCALAPPDATA`.

## Captured screens and reason

| Screen | Reason it is in the release gallery |
| --- | --- |
| `loading` | Verifies the loading progress bar and the six localized travel tips at both sizes. |
| `title` | Verifies Literata display copy, authored menu icons, focus treatment, button surfaces and the painted title backdrop. |
| `stats` | Verifies G7 local statistics: overview, per-difficulty rows, tabular numerals and the device-only note. |
| `credits` | Verifies the NG+ banner/title line, license copy and the new credits header icon. |
| `settings-reduced` | Shows the settings layout with the reduced motion preference enabled; this is the visual half of reduced-motion acceptance. |
| `homestead` | Verifies the in-world HUD, quest tracker icon, objective panel and the dusk palette over the settlement. |
| `village-rain` | Verifies weather presentation, the settlement silhouette and HUD legibility during rain. |
| `trade` | Verifies the town menu, faction identity band, action icons and the localized trade layout. |
| `world-map` | Verifies the atlas, town/road/explored/player markers, the live legend and the keyboard map flow. |
| `codex` | Verifies G2 Codex categories, unlocked and locked entries, the entry body and the labeled close action. |
| `inventory` | Verifies equipment slot icons, the two-pixel slot frames, rarity colors and item rows. |
| `settlement` | Verifies G6 visible tiers: Citadel tier 4 badge, ten building tiles with three pips each, and semantic happiness/health meters. |
| `diplomacy` | Verifies the council faction strip, all eight faction identities, the escalation ladder and treaty controls. |
| `ending-staged` | Verifies the campaign finale typography, banner, title line and the Second Oath / continue actions. |

## Staged sample state

The gallery is an acceptance fixture, not a claim about a fresh save:

- The local profile was seeded through `ProfileStats.begin_run`/`finish_victory`/`finish_defeat` so the statistics screen has representative rows.
- The credits frame uses a staged NG+ level 2 snapshot (`Wanderer's Banner`, title `Stormfast`) supplied to the credits panel only.
- The world is a real NG+ level 2 campaign with the Wanderer and Peace oaths. Its starting stockpiles were staged and all ten settlement buildings were raised through `WorkshopSystem.build` so the tier 4 state is visible.
- The finale frame is staged with the diplomatic route, 60 completed quests and 8 days for a deterministic composition.

These fixtures live in a temporary QA profile and are discarded after capture.

## Review result

The first capture pass exposed three real presentation defects, all fixed before the final set was accepted:

1. Codex tabs displayed raw node names (`Category_history`) instead of localized category titles.
2. The Codex close button had an icon and no readable label.
3. Settlement happiness and health used the danger red fill even at healthy values; they now use semantic sage/brass/danger fills.

The final set was inspected at native size in both locales and both viewports. Text does not clip, the eight council factions are all visible, the Codex labels localize, the settlement meters read correctly, and the reduced-motion toggle is visibly enabled in `settings-reduced`. Automated checks cover the design tokens, icon provenance and copy rules separately; final human playtesting remains an owner check in `HANDOFF.md`.

## Files

### EN, 1280×720

`en-1280x720-loading.png`, `en-1280x720-title.png`, `en-1280x720-stats.png`, `en-1280x720-credits.png`, `en-1280x720-settings-reduced.png`, `en-1280x720-homestead.png`, `en-1280x720-village-rain.png`, `en-1280x720-trade.png`, `en-1280x720-world-map.png`, `en-1280x720-codex.png`, `en-1280x720-inventory.png`, `en-1280x720-settlement.png`, `en-1280x720-diplomacy.png`, `en-1280x720-ending-staged.png`

### RU, 1280×720

`ru-1280x720-loading.png`, `ru-1280x720-title.png`, `ru-1280x720-stats.png`, `ru-1280x720-credits.png`, `ru-1280x720-settings-reduced.png`, `ru-1280x720-homestead.png`, `ru-1280x720-village-rain.png`, `ru-1280x720-trade.png`, `ru-1280x720-world-map.png`, `ru-1280x720-codex.png`, `ru-1280x720-inventory.png`, `ru-1280x720-settlement.png`, `ru-1280x720-diplomacy.png`, `ru-1280x720-ending-staged.png`

### EN, 1920×1080

`en-1920x1080-loading.png`, `en-1920x1080-title.png`, `en-1920x1080-stats.png`, `en-1920x1080-credits.png`, `en-1920x1080-settings-reduced.png`, `en-1920x1080-homestead.png`, `en-1920x1080-village-rain.png`, `en-1920x1080-trade.png`, `en-1920x1080-world-map.png`, `en-1920x1080-codex.png`, `en-1920x1080-inventory.png`, `en-1920x1080-settlement.png`, `en-1920x1080-diplomacy.png`, `en-1920x1080-ending-staged.png`

### RU, 1920×1080

`ru-1920x1080-loading.png`, `ru-1920x1080-title.png`, `ru-1920x1080-stats.png`, `ru-1920x1080-credits.png`, `ru-1920x1080-settings-reduced.png`, `ru-1920x1080-homestead.png`, `ru-1920x1080-village-rain.png`, `ru-1920x1080-trade.png`, `ru-1920x1080-world-map.png`, `ru-1920x1080-codex.png`, `ru-1920x1080-inventory.png`, `ru-1920x1080-settlement.png`, `ru-1920x1080-diplomacy.png`, `ru-1920x1080-ending-staged.png`

Reduced motion is captured separately from layout: `tests/test_comfort_preferences.gd` asserts that motion helpers snap when the preference is enabled, and `tests/test_design_pass.gd` asserts that the title backdrop stops its drift and UI scaling does not animate. The gallery’s `settings-reduced` frame records the preference state itself.
