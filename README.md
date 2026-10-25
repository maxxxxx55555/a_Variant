# Marchland Oaths — 1.5.0

Live Russian/English menu updates and 639 catalog keys, preserving the current save/difficulty selection. Four distinct Gemini/Lyria mood compositions, two 20-second musical finales, independent Master/Music/SFX/UI levels, reduced motion, functional credits and coherent application icons. Existing protected profiles and legacy user-data directories remain compatible.

## Русский

Живое переключение русского и английского языков без перезагрузки меню. Разные композиции для четырёх настроений, музыкальные финалы, четыре уровня звука, настройка анимации и экран авторов. Каталоги старых сохранений сохранены.

Current release: v1.5.0. Detailed provenance: assets/audio/SOUNDTRACK.md. Localization: docs/LOCALIZATION.md. Scope remains stylized indie art and does not claim GTA V scale. Portable Windows executables are not Authenticode-signed; offline save tamper evidence is not unbreakable DRM.

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
godot --headless --path . --export-release "Windows Desktop" builds/windows/MarchlandOaths.exe
python tests/run_tests.py --godot /path/to/godot --rendered --full-campaign --artifacts /path/to/logs
```

The runner executes 38 Godot cases per locale, plus Python verification, export, isolation, soundtrack and audio-asset checks. These cover 45 core regressions, 15 introductory playthrough checks, strategy, 639 RU/EN keys, sieges, civilians, cover, weapon models, triangle-exact cached terrain sampling, audio and saves. Complete diplomatic and military routes use actual movement, attacks, interactions and ordinary UI payments. The native verifier accepts `--military` for the conquest route. Normal difficulty is the full-route test baseline; other hardware and long unscripted play sessions require further independent QA.

Identical static assets share normalized meshes and preserve gameplay colliders. The 1.2 rainy village measured 5.07 seconds to load and 49.66 FPS over 180 rendered frames, with 337 draw calls at 1280×720 on this AMD integrated GPU. These are measurements from one machine.

## Release scope and verification

Version 1.5.0 is the localization, soundtrack and presentation update to the portable Windows desktop edition, built with Godot 4.7 Stable. It remains a small standalone game with original illustrations and licensed assets. Earlier design documents include broader ideas for future development; they are not a list of promised features in this edition.

The test runner imports the real project in Godot, exercises gameplay, save/load, audio controls and rendered UI. Packaged executables also contain an opt-in complete-playthrough verifier: `-- --verify-build`. It starts a new QA game, so use isolated APPDATA/LOCALAPPDATA folders. QA is silent through `GAME_AUDIO_MUTED=1`; this does not remove the player's music/effects controls. Folders and formats from the previous game names remain compatible.

The release report records the exact tested files, hashes, routes, screenshots and platform limits. Tests are automated in the actual engine; they do not constitute a long independent human playtest or testing on every graphics card. Portable Windows executables are not Authenticode signed. Keep third_party/Godot/LICENSE.txt, COPYRIGHT.txt and assets/audio/LICENSE.md when redistributing. The soundtrack “Stone Path to Dusk” has its own generation/provenance record; procedural sound effects are covered separately.

## 1.1.0 update

Textured KayKit houses, shops, foliage, props and animated characters replace primitive stand-ins. The title uses an original painted frontier illustration and the terrain uses a painted meadow surface. Help is compact by default; F1 expands the complete controls and tutorial. Camera bob/shake default to off for new profiles and remain configurable. Braking uses elapsed time.

Distinct folk compositions accompany exploration, settlements, combat, war and both endings. See assets/CREDITS.md for creator licenses, font notices and generation records.

## 1.2.0 update

The playable 3D world now uses PBR stone, plaster, timber and slate, detailed original house geometry, scanned rocks/barrels, a real sunset sky, wet surfaces, local rain, woven heraldic banners and optimized textured birch foliage. Characters retain the licensed animation with restrained colors and adjusted proportions. This is reference-inspired real-time scenery, not the pixel-identical photorealism of a pre-rendered illustration; characters and some props remain stylized.

Offline tamper evidence, schema/resource validation and atomic saves protect normal play and recover known-good backups. Valid legacy saves migrate once. Keep the whole user-data folder, including its installation key, when backing up protected saves. See SAVE-INTEGRITY.md for the precise guarantees and limitations.
