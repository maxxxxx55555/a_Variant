# Marchland Oaths 1.5.0 release design

The user adopted the release specification and explicitly selected direct main-branch execution. Existing published artifacts and private save identities remain compatible. Art direction and existing licensed assets are retained, with focused bilingual controls and independent soundtracks.

## Localization and settings
Audit the existing compiled RU/EN catalog and language-change listeners. Add a persisted first-launch language selection with a system-locale suggestion without changing campaign or save identities.
Use system-locale suggestion only for fresh settings. Explicit language choice and Master/Music/SFX/UI levels persist, bounded to valid values. Live language changes preserve current event, money, quarter, campaign and RNG state. Credits are a functional localized screen.

## Audio and repository boundaries
Retain spatial combat/footstep audio and independent cosmetic RNG.
Each gameplay mood has a distinct appropriate composition; retain the existing supplied title/exploration theme and its original provenance. Request new music via the documented Gemini API using environment credentials only; capture truthful service errors and use the explicitly permitted original synthesized fallback only if necessary. Victory and defeat receive distinct musical stingers. All QA remains muted.

## Delivery
Run baseline and final suites, bilingual presentation and layout tests, packaged native victory/defeat routes, three sequential stability checks, compatibility/tamper checks, performance and real screenshot inspection. Complete both sixty-objective campaign routes and material-lifetime regressions.
Guard origin before every Git operation, stage explicit paths, use game-name commit prefixes, preserve unique old branches, publish immutable per-game tags and bilingual notes. Document exact evidence and remaining platform/audio limitations; do not claim invulnerability or AAA production scale.
