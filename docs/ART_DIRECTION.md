# Marchland Oaths — art direction 1.6.0

A lived-in frontier atlas. A sunlit, cool-shadowed valley and physical road network carry the world; graphite panels, brass wayfinding and readable parchment-colored text carry decisions. The painted title, licensed PBR architecture and the actual road network shared by the world and the keyboard-accessible atlas remain the signature. 1.6.0 adds the Second Oath presentation, the Codex, the quest tracker, visible settlement tiers and a consistent design system without changing the world's material identity.

## Palette 1.6.0

| Token | Hex | Use |
| --- | --- | --- |
| Ink | #1E242A | Page and panel backing; deepest UI layer |
| Panel | #2A323A | Standard panel and button surfaces |
| Panel deep | #171C21 | Title backdrop, modal shade, boot depth |
| Parchment | #E8DCC3 | Primary copy, headings, focus ring |
| Chalk | #DCE3E9 | Long-form body copy and numeric readouts |
| Mist | #91A0A7 | Secondary copy, hints, map labels |
| Sage | #72968B | Explored/settled landmarks, codex section headers |
| Brass | #C9A227 | Titles, selected routes, tier 3–4, legendary rarity |
| Danger | #B4534B | Damage, blocked actions, progress fill |
| Edge | #61717A | One-pixel optical dividers and disabled strokes |

Contrast is measured on the actual surfaces: Chalk and Parchment stay at or above 7:1 on Ink and Panel, Mist at or above 4.5:1, and Brass at or above 4.5:1. Danger is never the only signal; it is paired with a label, icon or shape. Rarity colors remain common C8CDD2, uncommon 7FB069, rare 5B84C4, epic 9A6CC4 and legendary C9A227. Settlement tier colors: names at tier 1–2 use #E8DCC3, tier 3–4 use #C9A227, and the unbuilt tier 0 uses #9aa8a8.

The faction palette is CVD (color-vision-deficiency) audited. Woodland Freeholders #528034, Iron Guild #639cc0, Borderland Watch #83392f, River Covenant #9ce4de, Stone Circle #cab080, Marsh Keepers #342f5b, Sunfield Union #f9e59c and Pass Clans #ae8265. Separation was simulated with the Machado protan, deutan and tritan matrices and measured in CIELAB. The minimum Delta E is 41.2 for normal vision, 22.4 under protanopia, 14.5 under deuteranopia and 22.1 under tritanopia, above the 12 Delta E release floor. Faction identity is additionally carried by name and council row order, never by color alone.

## Typography

Literata carries display and headings at weights 600 and 700, with the `wght` variation axis and the `0x77676874` feature tag enabled. Golos Text carries body copy at weight 500. Both fonts ship with their OFL license files; no system font is assumed.

Desktop measurements use the 1920×1080 design viewport and scale to 1280×720. Display 56 px, major panel titles 32 px, selected section titles 28 px, body and commands 23 px, compact help 18 px, map and legend labels 24 px, numeric counters at the surrounding size with tabular numerals (`tnum`). Do not drop effective body text below 15 px at 1280×720. Longest English and Russian strings are checked on the minimum viewport before a screen is accepted. Line height is 1.25 for body, 1.2 for captions and 1.1 for display. Sentence case, short action verbs and plain cost/consequence details; fuller directions live in accessible tooltips and help surfaces.

## Icons and symbols

The interface uses 46 repository-authored 24×24 SVG line icons in `assets/ui/icons/`, drawn with 2 px rounded parchment (#e8dcc3) strokes in a single `<g>` group with no text, embedded raster or filter effects. They are released under CC0-1.0 as repository-authored work; exact provenance hashes live in `assets/ui/icons/provenance.json` and can be regenerated with `tools/generate_ui_icons.py`. Dedicated equipment slot icons (head, torso, legs, weapon) replace text-only slots. Icons are applied with `IconSet.apply()` at 20–36 px and never carry meaning alone: buttons keep localized labels, and map markers keep distinct silhouettes.

Map symbols: brass circle = town, pale line = road, sage diamond = explored site, white triangle = player, outlined circle = selection. The legend updates live with locale and all towns remain keyboard-selectable. Environmental signs use keyed copy. Weapon silhouettes, hands/rig, walking cycles, recoil and banking are inspected in final rendered views; no new animation claim follows from a still image alone.

## Layout, controls and motion

Use an eight-point layout grid: 8/16/24/32/48/64 px; one-pixel optical dividers and two-pixel focus rings are deliberate exceptions. Panels use 8 px radii; the authored button nine-slice uses 12 px corners. Buttons have distinct normal/hover/pressed/disabled surfaces, 24 px horizontal and 12 px vertical padding, and a minimum 48 px pointer/touch target. Focus is a two-pixel Parchment outline, never color alone; Tab follows screen order, Escape/Back returns to the previous screen. Disabled controls stay readable, keep their tooltip explanation and never become invisible.

Transitions last 160–180 ms: hover/focus scale 1.02 over 160 ms, view reveal 180 ms ease-out, dismissal snappier. Hover never resizes the interactive target's layout, only its visual scale. Reduced motion snaps all scale, parallax and reveal animations to their end state; `SettingsManager.reduced_motion` is honoured by every motion helper and the painted title backdrop stops its pollen drift. Presentation tweens never change simulation, RNG, cooldowns or saved balances. There is no perpetual UI shimmer, pulsing or decorative animation loop. The title backdrop uses a fixed, deterministic 42-mote pollen field; it is motion, not gameplay.

The Codex, quest tracker, council, settlement, inventory and statistics screens all use the same theme tokens, heading weights, icon set and focus treatment. HUD quest tracking uses the authored objective icon and localized goal words rather than shape glyphs. Toasts, combat hit-stop and loot rarity pops all read from the same palette and honor the reduced-motion preference.

## Rendered gallery acceptance

The 1.6.0 gallery is stored in `docs/galleries/1.6.0/` — 56 images, 14 screens captured in both locales (RU and EN) at both viewports 1280×720 and 1920×1080: title, loading, statistics, credits, settings with reduced motion enabled, village in rain, homestead, trade, world map, Codex, inventory, settlement, diplomacy, and the staged campaign finale. `docs/GALLERY_ACCEPTANCE_1.6.0.md` records the capture command, staged state, the reason each screen exists and the human review result. The gallery is produced by `tests/capture_gallery.gd` against the real rendered game, not by mockups. Every image is reviewed for faces/hands/teeth, stray text, perspective, lighting, palette, clipping and UI legibility at both viewports in both languages. Inventory acceptance does not replace final rendered-screen acceptance.

## Asset curation and provenance

Keep source provenance visible in credits and asset metadata. Review every raster/vector for faces/hands/teeth, stray text, perspective, lighting, palette, clipping and UI legibility. Technical normal/roughness/UV maps are reviewed for their intended material role, not as displayed paintings. Generated art is curated; it is never relabelled as photographed or hand-painted by a human. Existing inherited license bytes are immutable. See `ASSET_REVIEW.json` for individual file decisions and the external release evidence for contact sheets. 1.6.0 icons are repository-authored vectors under CC0-1.0; no AI-generated raster was added.

Locomotion uses the existing licensed Walk/Jog_Fwd/Sprint clips with matched actual movement speed; idle is evaluated before culling. Source foot-range sampling measured reference speeds about 0.963/2.507/3.295 m/s. The visual adapter uses 0.96/2.51/3.29 and 180 ms gait blending; it is an in-place retarget, not a new foot-IK solver. `test_initial_idle_pose.gd` and `test_locomotion_gait.gd` reproduce the former T-pose and constant-pace fleeing defects.

## Sound style

Interface feedback stays below the music and action effects. Focus is a brief dry cue at −24 dB, rate-limited to 80 ms; it never follows passive pointer hover. Normal actions get one short click only when their handler has not already emitted purchase/sale/upgrade/crafting/error feedback. Unavailable actions use a subdued 220 ms two-tone cue at −10 dB; disabled controls stay quiet and explain their condition in text. Repeated short effects vary pitch 0.97–1.03 with a separate cosmetic RNG. UI gain remains independent, and forced QA mute always wins. Closing a control retains its accepted-action acknowledgment without retaining the destroyed node.

The existing four distinct mood compositions and two 20-second musical finales retain their recorded Gemini/Lyria provenance and original mastered files. The 80 ms focus and 220 ms unavailable cues are repository-authored synthesis, CC0-1.0; no third-party recording or music-generation claim is attached. `assets/audio/interface-provenance.json` records exact WAV and generator hashes. See `AUDIO_FEEDBACK.md` for action coverage and regression evidence.
