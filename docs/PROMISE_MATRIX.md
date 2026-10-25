# Marchland Oaths: promise-to-edition matrix

The older design documents contain a much larger roadmap. This matrix indexes every substantive non-code line, including duplicated/extended design-book sections. It distinguishes actual edition systems from excluded roadmap details. Mandatory v2 improvements are included work and must pass their separate phase gates. A historical partial promise is never silently described as fully implemented.

[Complete verbatim inventory](PROMISE_MATRIX.json). 3278 paragraph/list/table entries. Sources and hashes are recorded; each group links to real engine tests. Final F7 logs determine test status.

| Original section | Status | Current edition / evidence | Explicit exclusions |
|---|---|---|---|
| 1 | partial | Windows, offline Godot4.7 and compact edition; broad hardware/FPS/HDD targets are not certified. [Test](../tests/test_identity.gd) | Unverified GPU/HDD targets |
| 2 | implemented | Development rules are enforced by guarded commits, resource validation and the v2 gate. [Test](../tests/test_repo_isolation.py) | — |
| 3 | partial | First-person combat plus settlement, diplomacy and conquest; diplomatic, military and mixed endings. [Test](../tests/test_campaign.gd) | Separate economic/liberation victory conditions |
| 4 | partial | Connected systems and real transactions; this is the compact edition described below. [Test](../tests/test_strategy.gd) | Every expanded roadmap simulation detail |
| 5 | partial | Explore, fight, brew, manage and resolve the campaign; reward pacing is not a guaranteed timed schedule. [Test](../tests/test_campaign_routes.gd) | Guaranteed10-minute rewards and multi-hour pacing |
| 6 | partial | Connected4000-unit terrain,14 towns,8 regions,40 POIs, danger/road discovery and paid travel. [Test](../tests/test_campaign.gd) | Enterable caves/cellars, apiaries/mills as separate playable systems |
| 7 | partial | Road network, vegetation clusters, scenery and readable landmarks; road-density review belongs to the art pass. [Test](../tests/test_terrain_sampling.gd) | Complete interior navigation and an everywhere/off-road30-second guarantee |
| 8 | partial | Calendar, seasons, five weather states and their supported numeric modifiers; civilian routines. [Test](../tests/test_civilians.gd) | Animal panic/lightning propagation, persistent snow tracks, extinguishable world fires |
| 9 | partial | Eight profiles, bounded relations/threat/escalation,5 treaty types, gifts and alliance/conquest progress. [Test](../tests/test_strategy.gd) | Independent regional economies, spies, hostages, nine contract types and bespoke red-line negotiations |
| 10 | partial | Aggregated jobs, health/happiness, housing, supply, migration and constrained enlistment. [Test](../tests/test_strategy.gd) | Sex/age demographics, water supply, epidemic transmission and refugee-management simulation |
| 11 | partial | Food/wood/ore/stone/gold production, upkeep, resource trading, taxes and workshop bonuses. [Test](../tests/test_strategy.gd) | Physical robbable caravans, autonomous inter-region supply chains, separate cloth/leather/ammunition stocks |
| 12 | partial | Four unit types, selectable squads/orders/three formations, upkeep and blockade/assault/surrender. [Test](../tests/test_siege.gd) | Cavalry, command wheel/selection rectangle, full RTS movement and individual ammunition logistics |
| 13 | partial | WASD/look/sprint/jump, melee attack/block, stamina, wear, ordinary death penalties and iron death. [Test](../tests/test_gameplay.gd) | Timed parry/dodge invulnerability, player ranged combat and separate physical damage schools |
| 14 | partial | Camp melee/ranged opponents, line-of-sight/cover and3 named bosses with actual combat. [Test](../tests/test_combat_cover.gd) | Wildlife ecosystem, corpse/door investigation and coordinated animal pack simulation |
| 15 | partial | Tiered equipment, one-time campaign kills/exploration, defined loot and meaningful rewards. [Test](../tests/test_campaign.gd) | Full legendary clue chronicles and dismantling/smelting every unwanted item |
| 16 | partial | Inventory list, weight, item comparison, head/torso/legs/weapon equipment, use/drop/repair. [Test](../tests/test_gameplay.gd) | Paper-doll grid/filter system, separate hands/feet/cloak/offhand and four configurable quick slots |
| 17 | partial | 25 potion recipes, ingredient checks, immediate atomic brewing and12 forge blueprints. [Test](../tests/test_campaign.gd) | Timed brewing, potion-quality tiers/skill-based failure, magic/mana/bombs/scrolls |
| 18 | partial | Progress through equipment, campaign objectives, recruited companions and regional relationships. [Test](../tests/test_campaign.gd) | Four character skill trees, player perk unlocks and reputation-title dialogue trees |
| 19 | partial | 60 dependency-linked objectives, eight regional chains and four companion recruitments. [Test](../tests/test_campaign_routes.gd) | Twenty fully authored narrative chains, procedurally branching investigations and NPC-heir quest substitution |
| 20 | partial | Four companion actors and nearby profession-based civilian schedules; distant aggregate state. [Test](../tests/test_civilians.gd) | Individual needs/dialogue/relationship simulation for every villager |
| 21 | partial | Compact HUD/F1 help, journal/council/map, comparison inventory, settlement/town/workshop screens. [Test](../tests/test_clear_play.gd) | Minimap, command wheel, full grid inventory and authored ambient breath/heartbeat system |
| 22 | implemented | RU/EN keyed catalogs, placeholder/glyph audits, persistent live language and first-launch selection. [Test](../tests/test_localization.gd) | — |
| 23 | partial | Licensed stylized figures, PBR scenery, Filmic environment, non-volumetric distance fog and restrained UI. [Test](../tests/test_art_assets.gd) | SDFGI/SSR/SSAO/volumetric fog, photoreal scale and ultra-low polygon counts for all licensed models |
| 24 | partial | Four unique mood tracks, two finale stingers, spatial effects/material footsteps and real audio buses. [Test](../tests/test_audio.gd) | Spoken dialogue, choir guarantee and six fully separate reverberation-zone presets |
| 25 | partial | Authenticated/validated/atomic saves and resource boundaries; new data/QA/encryption guarantees are gated in F5. [Test](../tests/test_save_guard.gd) | Unbreakable offline DRM or runtime memory-editor prevention |
| 26 | partial | MultiMesh vegetation, distance limits, cached art/resources and measured available-host performance. [Test](../tests/test_house_cache.gd) | Five-hour hardware certification and identical performance across all GPUs |
| 27 | partial | Signal-driven autoloads, resource-backed data, modular systems and checked runtime schemas. [Test](../tests/test_verification.py) | Exact historic class/file names when equivalent edition implementations exist |
| 28 | partial | 15-step introductory route, four difficulty levels plus independent iron flag; language/audio/camera/MSAA/reduced motion. [Test](../tests/test_release_details.gd) | Full key rebinding, axis inversion, UI-scale/color-blind presets, shadow/fog/draw-distance sliders |
| 29 | partial | Five manual slots, autosave, independent iron slot, backups/migration and finale/exit persistence. [Test](../tests/test_release_hardening.gd) | Political-collapse/capital-loss defeat conditions outside permanent iron death |
| 30 | implemented | Historical stages are superseded by the adopted v2 sequential evidence gate. [Test](../tests/test_repo_isolation.py) | — |
| 31 | implemented | Automated acceptance is attached to real tests; final v2 evidence is generated after changes. [Test](../tests/test_repo_isolation.py) | — |
| 32 | implemented | Repository, licensing, no-placeholder and public-history rules remain binding. [Test](../tests/test_repo_isolation.py) | — |
| 33 | partial | The current edition and v2 gate determine shipping scope; larger historical checklists are indexed here. [Test](../tests/test_campaign.gd) | Any unimplemented broader roadmap item above |
| 34 | implemented | Historical report template is process guidance, not additional playable content. [Test](../tests/test_repo_isolation.py) | — |
| 35 | partial | Coherent compact gameplay and legible consequences are the direction, with measured checks. [Test](../tests/test_clear_play.gd) | A universal subjective guarantee of fun or perfection |
| 0 | implemented | Historical operator/development guidance is retained as an archive; v2 and current edition scope supersede it. [Test](../tests/test_repo_isolation.py) | — |

The same exclusions are visible from the README edition-scope section. These exclude additional roadmap features, not broken accessible controls. No button advertises an excluded feature. Both public-history and creator-license bytes are preserved.
