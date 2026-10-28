# Art and audio credits — 1.5.0

Original in-game illustrations and meadow texture: OpenAI image generation, created for this edition. Generation records and SHA-256 digests are in assets/art/*provenance.json.

Fonts: Manrope, Prata and Alegreya from Google Fonts, SIL Open Font License 1.1. Full notices are in assets/fonts/*-OFL.txt. Original download URLs and digests are in asset-sources.json.

Music: “Stone Path to Dusk”, generated in Google Gemini / Lyria on 2026-10-24. Full prompt, original and mastered-file digests, terms and quiet-loop processing are recorded in assets/audio/music-provenance.json and LICENSE.md. Sound effects have separate CC0 provenance.

Buildings, nature and props: KayKit Medieval Hexagon Pack 1.0 by Kay Lousberg, CC0 1.0. https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0
Animated characters and three weapon models: KayKit Character Pack Adventures 1.0 by Kay Lousberg, CC0 1.0. https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
Creator license texts are in assets/art/medieval/LICENSE.txt and assets/art/characters/LICENSE.txt. Imported meshes are normalized for existing gameplay footprints. Original animation and textures are retained, with muted fabric/metal shading and adult proportion adjustments. Source revisions, individual URLs and digests are in asset-sources.json.

PBR surfaces, scanned moss rocks, barrel, birch and Belfast sunset sky: Poly Haven, CC0 1.0 Universal. https://polyhaven.com/license — individual download URLs, original digests and derived foliage records: assets/art/realistic/sources.json. Original high-poly tree sources are excluded from the runtime; simplified 3D branches and orthographically rendered transparent canopy atlases form the game mesh. Buildings are original procedural architecture using these licensed surfaces, rather than scans of complete buildings.

Asset research used the Poly Haven public API. Powered by Poly Haven: https://polyhaven.com/our-api — the shipped game has no live API dependency.

## 1.3 interface
Original scalable satin control surfaces. New OFL type families: Golos Text and Literata. Font notices and exact source digests accompany the assets.

## 1.3 detailed figures
Quaternius Universal Base Characters, Modular Character Outfits - Fantasy, Universal Animation Library (CC0). Face/neck triangle crop, typo corrections in creator texture URIs, shared rig binding, rest-pose animation transfer and material variants are project adaptations. Creator URLs, exact shipping asset hashes and CC0 notices accompany assets/art/humans. Original source ZIPs remain in the local art pipeline outside shipping assets.

## 1.5.0 soundtrack

Four mood recordings and two musical finale cues, generated using Google Lyria RealTime. Track names, prompts, original/mastered hashes and generated-output terms: assets/audio/music-provenance.json and SOUNDTRACK.md. Synthesized interface/game effects retain separate CC0 provenance.

## 1.5.0 application icons

Original project artwork authored for this release, without third-party image sources. The scalable `icon.svg` and raster `assets/ui/app-icon.png` form the application icon family.

- `icon.svg`: SHA256 `c06c567fc0c4375aa0a3dc87b76224d91b71c259f05b2181cc4a4498e1fc7ed5`.
- `assets/ui/app-icon.png`: SHA256 `adba04819d8eaf4b4aea878d571ab16514e69a8f21f3acb6ea7bfbb342178f39`.

V2 art curation: docs/ART_DIRECTION.md and docs/ASSET_REVIEW.json. Roadside landmarks and meadow blade refinement are code-built repository geometry using the existing licensed surfaces. The crest background clipping repair and derived executable-icon hashes are recorded in assets/ui/icon-provenance.json. Inherited third-party license files are retained unchanged.

Interface focus/unavailable cues: original profile-specific synthesis using tools/generate_audio.py, CC0-1.0; exact provenance is in audio/interface-provenance.json.

## Marchland interface illustrations

The colorful SVG item icons in `assets/ui/items/` and the updated frontier crest in `icon.svg` are original repository-authored vectors for this game. `assets/ui/app-icon.png` is rendered from that vector using `tools/render_icon.gd`; its exact source and output hashes are recorded in `assets/ui/icon-provenance.json`.
