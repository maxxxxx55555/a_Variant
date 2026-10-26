# Marchland Oaths: repository isolation audit

2026-10-25. The adopted audit was checked against the actual 1.4 source before editing. No new misplaced asset needing transfer was found. Shared audio-generation tooling is intentional and explicitly allowlisted; no game content is copied between repositories. Original license bytes and legacy save directories stay intact.

| Item | Finding / action |
|---|---|
| C1–C2 | Spatial audio/effects belong here and are retained. |
| C3 | Four moods shared one background file. New per-mood compositions and finale stingers are tracked in the release audio catalog/provenance. |
| C4 | Existing RU/EN catalog is retained and audited. |
| C5–C6 | Release work is directly on main as requested. Ancestry is recorded before deleting only fully merged branches; unique branches are preserved. |
| C7 | No unsafe root push helper found. |
| C8 | Published history is immutable. Local commit titles begin with this game name; the published CI-title exception below is recorded without rewriting history. |
| C9 | Legacy user-data directory deliberately unchanged for authenticated-save compatibility. |
| C10 | Baseline counts verified against executed suite logs; final counts must include the new suites. |

## Commit guard
`tools/check_repo_isolation.py` scans staged content before every local commit. Its negative fixtures include foreign identifiers deliberately; the guard and tests are documented shared tooling by design. It blocks real credential values, generated builds/caches and foreign content, without deleting anything. It also supports a full tracked-tree audit via `--tree`. Ordinary words in third-party license notices are not rewritten. Public history is not rewritten.

## Final tracked-tree audit
Two historical1.4 planning documents contained a joint project plan. They now retain only this project's own design and validation scope; the other project already has its own originals, so no content transfer was needed. The full tracked-tree isolation check covers historical documents as well as shipping sources.

## v2 reconciliation (2026-10-26)
C11/C12 describe a different architecture and require no content transfer here. The current localization catalog remains authoritative. New v2 work is tracked in RELEASE_V2_PLAN.md; earlier audit rows are historical baseline observations, not final gate claims.

## C13: historical design-copy contamination found by v2
Three archived design/plan files still mixed unrelated runtime architecture and validation scope despite lacking an exact foreign game title. Each now contains only this game's own design. The canonical design content already exists in its proper repository; no new asset transfer or license edit was necessary. Two new negative tests reproduce the old guard's failure. The guard now rejects copied design labels and foreign runtime paths as well as game names. Full tracked-tree scanning catches the old text before cleanup and passes afterward.

## F2 closure evidence
See LOCALIZATION_AUDIT.md for the keyed-copy contract, localized ingredient-feedback regression and actual executed suite inventory. The inherited runner count was corrected; optional campaign route cases are counted separately.

## Published workflow title exception — preserved history

GitHub asynchronously inserted its generated subject before the intended title was appended. Commit `fadde7735e41658432007fee5dedc636050a095c` therefore reads `Add GitHub Actions workflow for GDScript warningsMarchland Oaths: enforce all shipping warnings in CI`, rather than beginning with the required game prefix. Its reviewed26-line workflow is correct and strict hosted CI passed. This is a process error, not a cross-game content transfer or gameplay defect. The public commit is preserved under the no-history-rewrite rule. The exact-prefix exception remains visible in the historical audit; no claim is made that this title follows the prefix rule. The human-adopted continuation uses its section6 release gate, based on current software acceptance, repository isolation and clean saved trees. Keep proper prefixes for all further commits and retain this history rather than rewriting it.

## Final byte-contract review
The promise inventory now hashes portable LF inputs without dropping any original claim. Inherited licenses and protected-save fixtures use opaque Git attributes so fresh checkouts preserve their published bytes. The release license test compares the original1.4.0 archive directly; all14 inherited files match. Existing working bytes were already correct. No license wording changed. C10 final suite counts are62 rendered invocations per locale here.
