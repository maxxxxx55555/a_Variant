# Marchland Oaths — 1.5.3 candidate

This source is a 1.5.3 release candidate. The published 1.5.2 build remains available; the new build requires fresh release validation.

## Current edition scope

The compact campaign has60 dependency-linked objectives across eight regions,14 towns and40 points of interest, four recruitable companions, four squad types,25 potion recipes and12 forge blueprints. Its endings resolve alliances, conquest or a mixture. Boot/loading tips, persistent camera/MSAA controls and explicit failed-save exit handling are included in this edition.

The older GAME_DESIGN/FULL_BOOK are a broader archived roadmap, not additional advertised features. **Not in this edition:** enterable cave/cellar networks, physical caravan robbery/escort economy, individual age/sex/water/epidemic simulation, player skill trees, timed parry/dodge invulnerability or player bow combat, extra equipment slots/grid/filter UI, command-wheel/RTS selection, cavalry, full branching narrative investigations, six reverb zones, advanced accessibility/render presets, and separate economic/liberation/political-collapse endings. Individual differences and all original promises are indexed in [the edition matrix](docs/PROMISE_MATRIX.md); its complete inventory retains the original words and line references. Compatibility rendering uses non-volumetric fog and does not provide SDFGI/SSR/SSAO. Performance figures describe the tested host, not every hardware target.

## 1.5.2 repair

Ordinary Git checkouts now use the committed LF bytes consistently: critical-data hashes and the compiled trust anchor match those bytes, and interface SFX provenance identifies the unchanged canonical generator source. Real checkout regressions exercise both `core.autocrlf=true` and `false` without local attribute overrides; CI and the source runner enforce them. Existing public tags and assets remain immutable.

Retained: Live RU/EN presentation with687 catalog keys, four mood compositions and two musical finales, independent audio levels, reduced motion, credits and protected1.4.0/1.5.0 profiles. Current content: 60 dependency-linked objectives, eight regions,14 towns,40 points of interest, companions, settlement management and diplomatic/military/mixed endings.

## Русский

Исправлена воспроизводимая сборка из обычного Git-checkout: манифест данных и происхождение интерфейсных звуков соответствуют исходным LF-байтам. Игровые правила, музыка и защищённые сохранения не меняются. Сохраняются русская и английская локализации и совместимость профилей1.4.0/1.5.0.

## Validation and limits

Normal Exit, window close and guarded QA rejection now wait for actual audio playback disposal before terminating. Save failures retain Retry/Stay/Discard, repeated accepted dialog callbacks cannot write twice, and private verifier cleanup remains reusable. Source test drivers drain audio explicitly and the runner rejects resource-leak warnings.

Coverage: 67 rendered Godot cases per locale;192 mechanics cells; actual campaign, save, integrity and UI routes, plus Python checkout/provenance/license/copy/export contracts. Fresh complete source/native/soak results and exact artifact hashes are recorded by the release gate and current acceptance certificate. Earlier release measurements are historical and do not establish acceptance of this patch.

See [patch notes](docs/RELEASE_1.5.2.md), [acceptance certificate](docs/ACCEPTANCE_CERTIFICATE.md), [mechanics coverage](docs/MECHANICS_MATRIX.md), [save integrity](SAVE-INTEGRITY.md) and [the scoped promise inventory](docs/PROMISE_MATRIX.md). Portable Windows x64; Godot Compatibility/OpenGL-capable GPU; offline. The EXE is not Authenticode signed. Android artifacts are omitted. Finite automated tests do not replace owner play/listening checks or guarantee zero possible bugs, unbreakable offline security or AAA scale.

---

# Marchland Oaths —1.4.0

The town menu now opens on Journey, with Trade and Siege on separate focused tabs. Trade quotes come from the actual transaction price function, and unaffordable actions are disabled before a failing click. Costs stay visible; full route instructions expand on demand. The HUD uses shorter captions with shortcut tooltips and F1 help. Smooth rounded controls and4xMSAA refine the presentation while keeping the existing detailed animated figures, PBR world, soundtrack and protected profiles.

# Marchland Oaths — 1.3.0

Golos Text body typography, Literata headings and authored slate/pewter controls refresh the interface. Licensed CC0 Quaternius modular human characters add anatomically proportioned heads, clothing, hair and surface maps, retargeted idle/walk/attack animations and hand-attached weapons. Authored steel/leather/brass swords and crossbows distinguish melee and ranged units. A focused illustrated epilogue presents the actual campaign result. Existing PBR scenery, distinct acoustic music and protected saves are retained.

Presentation remains stylized indie art; this update does not claim GTA V scale. Existing save directories and gameplay rules are preserved.

# Marchland Oaths — 1.2.1

Nested buffs, buildings, diplomacy, faction escalation, squads, sieges, tutorial and actor snapshots are validated before restoration. Legacy item metadata is rebuilt from the shipped catalog. Manual title-slot selection now controls the save target; new/loaded rosters cannot retain an invalid formation index. Expired strength buffs remain saveable, loot ingredients stack, and inventory capacity prevents unloadable profiles without charging failed crafting. Invalid resource transactions are rejected atomically. Failed saves show a clear localized warning. Existing PBR scenery, stylized characters and separate acoustic music are retained.

# Marchland Oaths

A first-person frontier RPG with settlement management, small armies and diplomacy. Unite eight regions through alliances, conquest or a mixture of both, then continue exploring after the ending.

## Play

Extract the whole Windows archive and run `MarchlandOaths.exe`. The illustrated title screen offers Russian/English, four difficulties, five manual saves, autosave and iron mode. Iron mode has permanent death.

Equip the starting sword through I, collect armor, defeat the first bandit and make the settlement's food production sustainable through B. Greenhaven's reeve is north of home: aim and press E. The journal J lists objectives; M opens the connected map. Menus pause the simulation.

Each region has supply deliveries, a camp, exploration and a report. Alliances require 60 trust and 100 gold. A paid gift improves trust. Report to the reeve after resolving the region to unlock the next road. All eight reports lead to a diplomatic, military or mixed ending. Companion oaths have additional stated requirements, including five surviving soldiers for the commander; replace real casualties through the recruitment menu.

## Sieges

Recruit at least three soldiers through R. A blockade costs 12 food, 8 wood and 15 gold, followed by 6 food and 2 gold per day plus normal upkeep. After a day, an assault costs another 10 wood and 5 food. Use ordinary attacks to breach the physical gate and defeat the garrison. After three supplied days, an exhausted garrison can surrender. Insufficient soldiers or supplies lift the blockade. Gate damage, army casualties and siege state are saved.

## Controls

WASD move; mouse look; Shift sprint; Space jump; left mouse attack; right mouse block; E interact; Q potion; I inventory; C alchemy; B settlement; R/F/J army/diplomacy/journal; M map; Esc close/pause. Weapons have six visible silhouettes. Enemy and allied attacks respect solid cover. Nearby damage displays a brief health readout and hit confirmation.

## Contents

A connected 4×4 km terrain, eight factions, fourteen settlements, forty marked locations, sixty objectives, four companions, three bosses, seventy equipment items, twenty-five potions/recipes, twelve crafting blueprints and ten building types. Jobs, population, laws, food, salary, morale, equipment wear/repair, seasons and weather influence progression. Forty-two cosmetic civilians follow daytime routines and flee nearby combat without blocking required quest access. The terrain, sky, animated meadow cover and fields combine procedural scenery with textured creator models for buildings, characters, trees, shops and props. The regional objective structure is deliberately repeated across the frontier.

## Build and test

Open `project.godot` in Godot 4.7 and press F5, or use:

```text
python tools/build_manifest.py --check
# Set GODOT_SCRIPT_ENCRYPTION_KEY and GODOT_WINDOWS_RELEASE_TEMPLATE privately in the build environment.
python tools/export_release.py --godot /path/to/godot --output /fresh/staging/MarchlandOaths.exe
python tests/run_tests.py --godot /path/to/godot --rendered --full-campaign --artifacts /path/to/logs
```

The current source runner contains 67 Godot invocations per locale with --rendered, including import; --full-campaign adds two complete route cases (69 rendered total). Final executed counts are recorded in the gated release evidence. Python checks cover resources, export, copy/edition contracts, isolation, soundtrack and audio assets. These include46 core gameplay assertions,15 introductory playthrough checks, strategy, 687 RU/EN keys, sieges, civilians, cover, weapon models, triangle-exact cached terrain sampling, audio and saves. Complete diplomatic and military routes use actual movement, attacks, interactions and ordinary UI payments. The native verifier accepts `--military` for the conquest route. Normal difficulty is the full-route test baseline; other hardware and long unscripted play sessions require further independent QA.

Identical static assets share normalized meshes and preserve gameplay colliders. The 1.2 rainy village measured 5.07 seconds to load and 49.66 FPS over 180 rendered frames, with 337 draw calls at 1280×720 on this AMD integrated GPU. These are measurements from one machine.

## Release scope and verification

Version 1.5.1 was the v2 localization, soundtrack, presentation and integrity successor to the portable Windows desktop edition, built with Godot 4.7 Stable. It remains a small standalone game with original illustrations and licensed assets. Earlier design documents include broader ideas for future development; they are not a list of promised features in this edition.

The test runner imports the real project in Godot, exercises gameplay, save/load, audio controls and rendered UI. Public executables physically omit the complete-playthrough verifier and reject QA arguments. Only the separate, unpublished QA preset supports `-- --verify-build` with `GAME_QA=1`; it starts a fresh QA game in isolated APPDATA/LOCALAPPDATA folders. QA is silent through `GAME_AUDIO_MUTED=1`; this does not remove the player's music/effects controls. Folders and formats from the previous game names remain compatible.

The release report records the exact tested files, hashes, routes, screenshots and platform limits. Tests are automated in the actual engine; they do not constitute a long independent human playtest or testing on every graphics card. Portable Windows executables are not Authenticode signed. Keep third_party/Godot/LICENSE.txt, COPYRIGHT.txt and assets/audio/LICENSE.md when redistributing. The soundtrack “Stone Path to Dusk” has its own generation/provenance record; procedural sound effects are covered separately.

## 1.1.0 update

Textured KayKit houses, shops, foliage, props and animated characters replace primitive stand-ins. The title uses an original painted frontier illustration and the terrain uses a painted meadow surface. Help is compact by default; F1 expands the complete controls and tutorial. Camera bob/shake default to off for new profiles and remain configurable. Braking uses elapsed time.

Distinct folk compositions accompany exploration, settlements, combat, war and both endings. See assets/CREDITS.md for creator licenses, font notices and generation records.

## 1.2.0 update

The playable 3D world now uses PBR stone, plaster, timber and slate, detailed original house geometry, scanned rocks/barrels, a real sunset sky, wet surfaces, local rain, woven heraldic banners and optimized textured birch foliage. Characters retain the licensed animation with restrained colors and adjusted proportions. This is reference-inspired real-time scenery, not the pixel-identical photorealism of a pre-rendered illustration; characters and some props remain stylized.

Offline tamper evidence, schema/resource validation and atomic saves protect normal play and recover known-good backups. Valid legacy saves migrate once. Keep the whole user-data folder, including its installation key, when backing up protected saves. See SAVE-INTEGRITY.md for the precise guarantees and limitations.

V2 visual pass: eight-point design tokens, curated source-asset review, corrected crest, tapered meadow, batched roadside landmarks and an actual-road atlas with keyboard navigation and a translated legend. See docs/ART_DIRECTION.md and docs/ASSET_REVIEW.json; historical release evidence is documented in docs/RELEASE_1.5.1.md.

## Release integrity

Public Windows packs omit the private verifier; the separate Windows QA preset additionally requires GAME_QA=1. All pack entries and the directory are encrypted using a matching custom Godot template and an environment-only build key. Encryption makes modification harder; it is not DRM. The compiled critical-data trust root rejects a replacement manifest and starts changed installations with trusted fallback data, a localized warning and no progress/settings writes. Authenticated save recovery records a local integrity log and shows a localized message. See SAVE-INTEGRITY.md for exact boundaries.

## 1.5.2 acceptance and distribution

Current [acceptance certificate](docs/ACCEPTANCE_CERTIFICATE.md), [owner checklist](docs/HANDOFF.md), [final report](docs/FINAL_REPORT.md) and [announcement kit](docs/ANNOUNCE_KIT.md) describe this patch. Older diagnostic documents/images refer to preserved historical attempts. Only the published gated patch ZIP and its exact versioned sums file are distribution artifacts.
