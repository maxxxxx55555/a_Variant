# Marchland Oaths — art direction

A lived-in frontier atlas. A sunlit, cool-shadowed valley and physical road network carry the world; slate panels, brass wayfinding and readable parchment-colored text carry decisions. Retain the existing coherent painted title and licensed PBR architecture. The signature is the same actual road network in the world and on the keyboard-accessible atlas, with restrained stone/wood landmarks and an explicit symbol legend.

## Palette and typography
- Deep slate #1C2932: panels and backing; dusk #172B30: boot and map depth.
- Chalk #DCE3E9: primary copy; mist #91A0A7: secondary/disabled copy.
- Brass #DFC692: titles and selected routes; sage #72968B: explored/settled landmarks.
- Clay #BD8A87: danger and damage; also pair with a label or symbol.

Literata regular:display56px, major panel title32px, selected section28px. Golos Text500:body23px, commands23px, compact help18px, map labels24px, legend24px; numeric counters use Golos500 at the surrounding text size. The menu is measured in the1920×1080 design viewport and scales to1280×720; do not drop body text below its effective15px there. Use the common spacing/control rules below. Keep architecture textures at consistent world scale with restrained normal strength. Filmic tonemapping, warm sun/cool sky, mild distance fog, shared scene-owned sky and4xMSAA are the Compatibility rendering baseline. Performance is measured on the release gallery world, not inferred from art screenshots.

Roadside detail stays off the navigable road, has no collision, uses local deterministic RNG and spatial MultiMesh batches. No gap along a long road exceeds120m (20s at the normal6m/s walk). Tapered segmented grass should read as a meadow, not thick triangular spikes; preserve open streets and interaction footprints. Materials retain licensed albedo/normal/roughness maps and do not introduce artificial neon saturation.

Map symbols:brass circle=town, pale line=road, sage diamond=explored site, white triangle=player; outlined circle=selection. The legend updates live with locale and all towns remain keyboard-selectable. Environmental signs must use keyed copy. Weapon silhouettes, hands/rig, walking cycles, recoil and banking are inspected in final rendered views; no new animation claims follow from a still image alone.

## Controls, layout and motion
Use an eight-point layout grid:8/16/24/32/48/64px; one-pixel optical dividers and two-pixel focus rings are deliberate exceptions. Panels use8px radii; the authored button nine-slice uses12px corners. Buttons have distinct normal/hover/pressed/disabled textures,24px horizontal padding,12px vertical padding and a minimum48px pointer/touch target. Disabled text stays readable and its tooltip explains the unmet condition. Focus is a two-pixel bright outline, never color alone; Tab follows screen order, Escape/Back returns to the previous screen. Icon strokes use2px at24px, rounded joins; map symbols also differ by shape.

Transitions last120–240ms:180ms ease-out for arrival and value settlement,120ms ease-in for dismissal where a delayed exit is appropriate. Reduced motion snaps. Presentation tweens never change simulation, RNG, cooldowns or saved balances. Avoid perpetual UI shimmer. Existing instant close/back remains instant for predictable navigation. Do not resize interactive targets during hover.

Text uses sentence case, short action verbs and plain cost/consequence details. Keep fuller directions in an accessible tooltip/help surface. No decorative implementation prose. Line height:body1.25, captions1.2, display1.1; avoid forced multi-line display titles. Check longest English and Russian strings on the minimum viewport before accepting a changed screen.

## Asset curation and provenance
Keep source provenance visible in credits and asset metadata. Review every raster/vector for faces/hands/teeth, stray text, perspective, lighting, palette, clipping and UI legibility. Technical normal/roughness/UV maps are reviewed for their intended material role, not as displayed paintings. Generated art is curated; it is never relabelled as photographed or hand-painted by a human. Existing inherited license bytes are immutable. See ASSET_REVIEW.json for individual file decisions and the external release evidence for contact sheets and integrated gallery acceptance. Inventory acceptance does not replace final rendered-screen acceptance.

Locomotion uses the existing licensed Walk/Jog_Fwd/Sprint clips with matched actual movement speed; idle is evaluated before culling. Source foot-range sampling measured reference speeds about0.963/2.507/3.295m/s. The visual adapter uses0.96/2.51/3.29 and180ms gait blending; it is an in-place retarget, not a new foot-IK solver. test_initial_idle_pose.gd and test_locomotion_gait.gd reproduce the former T-pose and constant-pace fleeing defects.

## Sound style
Interface feedback stays below the music and action effects. Focus is a brief dry cue at−24dB, rate-limited to80ms; it never follows passive pointer hover. Normal actions get one short click only when their handler has not already emitted purchase/sale/upgrade/crafting/error feedback. Unavailable actions use a subdued220ms two-tone cue at−10dB; disabled controls stay quiet and explain their condition in text. Repeated short effects vary pitch0.97–1.03 with a separate cosmetic RNG. UI gain remains independent, and forced QA mute always wins. Closing a control retains its accepted-action acknowledgment without retaining the destroyed node.

The existing four distinct mood compositions and two20-second musical finales retain their recorded Gemini/Lyria provenance and original mastered files. The new80ms focus and220ms unavailable cues are repository-authored synthesis, CC0; no third-party recording or music-generation claim is attached. assets/audio/interface-provenance.json records exact WAV and generator hashes. See AUDIO_FEEDBACK.md for action coverage and regression evidence.
