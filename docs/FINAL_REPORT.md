# Marchland Oaths 1.6.2 — release report

Release URL: none yet — no GitHub Release v1.6.2 exists. Runtime sources are from commit `f7a3155` plus the 1.6.2 completion commit on top of it. The last published release is [Marchland Oaths 1.6.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.6.1).

1.6.2 is a patch that closes two ways the 1.6.1 legacy-save confirmation could still be bypassed. A save written before signed profiles (schema v1–v3) carries no HMAC, because that format predates it, and 1.6.1 stopped applying such a file silently: the loader refused it, remembered it as pending, and the game asked once, in the active language, whether to import it into that slot. Two reviews found that a declined file could still be promoted into the slot's authenticated backup by a later ordinary save, and that an answer given for one file could be applied to different bytes swapped in while the dialog was open. Since 1.6.2, `_store` trusts a previous body only from the exact file just confirmed (otherwise the write proceeds with no backup candidate and the untouched original is preserved as `.rejected`), and consent is bound to a SHA-256 digest of the exact file text, per slot — if the bytes changed while the question was open, nothing is applied and the current body stays pending for a fresh question. No gameplay, balance or art changed, and no save format changed. Audio gets two small fixes: `purchase.wav` no longer duplicates `pickup.wav` (the generator gave both the same two bell notes; purchase now has its own arpeggio [76, 81, 84]), and the default music volume rises from 0.30 to 0.65 (the Lyria tracks measure RMS ≈ 2130, peak 0.28–0.43, so the old default left them barely audible). This completion also adds the missing 1.6.2 patch notes, acceptance evidence, certificate and report, corrects the stale version metadata (`export_presets.cfg` 1.6.0.0 → 1.6.2.0, README title, QUICK_START, CREDITS), and removes two empty autoload scripts (`WorldManager.gd`, `InputManager.gd`) that nothing used.

## What was verified

| Area | Result | Evidence |
|---|---|---|
| The declined-backup side door | PASS (asserted in code): declined-then-saved preserves the original as `.rejected` instead of promoting it | `tests/test_legacy_import.gd`, `scripts/autoload/SaveSystem.gd` (`_store`, `_read_previous`, `_preserve_rejected`) |
| The byte-bound answer | PASS (asserted in code): a file swapped while the dialog is open is not imported under the earlier answer; the current body stays pending and the player is told the file changed | `tests/test_legacy_import.gd`, `scripts/autoload/SaveSystem.gd` (`confirm_legacy_import`) |
| The confirmation | PASS (asserted in code): localized title, body and both actions; the accepted action holds keyboard focus; prompts are per slot | `tests/test_legacy_import.gd`, `docs/galleries/1.6.2/` |
| Confirmed import | PASS (asserted in code): restores the real 1.1 state and writes an authenticated schema 4 file | `tests/test_legacy_import.gd`, `tests/test_legacy_migration.gd` |
| Declined import | PASS (asserted in code): nothing is applied and the file is unchanged byte for byte | `tests/test_legacy_import.gd` |
| Existing slots | PASS (asserted in code): a checksum-only file is still refused in any slot holding authenticated progress | `tests/test_save_recovery.gd`, `tests/test_profile_contract.gd` |
| Source gate | PASS: editor import exit 0 + strict warning gate 105/105 (49 categories as errors) on a full checkout; Python contracts 10/10 | `docs/acceptance-1.6.2/suites.json` |
| Whole suite | PASS (headless): `tests/run_tests.py` 79/79 Godot cases, exit 0, on a full checkout. Rendered gate NOT RE-RUN: last executed rendered gate is 83/83 RU and 83/83 EN for 1.6.1 | `docs/acceptance-1.6.2/suites.json`, `docs/acceptance-1.6.1/suites.json` |
| Executed matrix | PASS: 32 mechanics × 8 columns = 256 cells, `EXECUTED_PASS` in RU and EN, re-executed for 1.6.2 | `tests/test_mechanics_matrix.py` |
| Soak | NOT RE-RUN: last measured soak is 3 complete campaign loops in 2546 s for 1.6.1 | `acceptance-1.6.1/soak.json` |
| Native builds | NOT RE-RUN: last native routes are 5/5 on the exported 1.6.1 builds | `acceptance-1.6.1/native.json` |
| Export integrity | PENDING: no 1.6.2 artifacts exist yet | `docs/acceptance-1.6.2/distribution.json` |
| Localization | PASS: 811 keys per locale, identical key sets, no missing translation; copy contract PASS. The 1.6.1 notes said 810 keys; that count was wrong by one (813 CSV rows: header, 811 keys, one empty row) | `tests/test_copy_contract.py`, `data/strings/en.csv`, `data/strings/ru.csv` |

## Performance

Not re-measured for 1.6.2. The 1.6.2 code changes no rendering, asset or scene code, so the recorded 1.6.1 medians stand as the no-regression baseline: scene load 7254 ms, 60.08 FPS, 356 draw calls, 295509 primitives (medians of three runs on the same Windows host; load time moves by hundreds of milliseconds between sessions).

## Artifacts

None for 1.6.2 yet. The latest published artifacts are the 1.6.1 ones: `MarchlandOaths.exe` (252281128 bytes, SHA256 `4db12ce899fdb19148b3307b21a2549d3fb21ea44651c430978f21c479efa50f`) and `MarchlandOaths.pck` (181017884 bytes, SHA256 `ad3b39ea572871e0fc109a0efa8565b8084a8c6f8a6b06cd7a3d20aebba0c287`), in `MarchlandOaths-Windows-1.6.1.zip` (478396417 bytes, SHA256 `845bc95693354f678c785524210f005cf2a57e50a9a49ab66c86f80d92648567`).

The public pack is directory- and file-encrypted; the private QA pack is never published. A stock Godot editor cannot mount the encrypted pack (`acceptance-1.6.1/pack-audit.json`). The encrypted export requires the private matching template and script-encryption key, which live outside the repository; the source tree in this commit is export-ready, but the published 1.6.2 ZIP and its sums can only be produced from the build environment that holds them.

## Open questions and limits

- The published Windows executables are not Authenticode signed; Windows shows its normal warning.
- The source gate ran on a Linux host with Godot 4.7 Stable, on a full checkout; the rendered gate, soak, native routes and published-binary smoke check were not re-run for 1.6.2 and are not a human playtest or a listening review.
- This patch removes two silent injection paths. It does not make offline integrity unbreakable: the installation key is readable by the device owner, and a patched binary is out of scope for any client-side protection.
- Whether the dialog wording is clear to a player is an owner judgement, listed in [HANDOFF](HANDOFF.md).
- The Ubuntu CI import step aborted intermittently in the engine allocator on 1.6.0 commits and passed on re-run; `docs/.gdignore` keeps documentation images out of that import.

## Русский

Marchland Oaths 1.6.2 — патч, закрывающий два пути обхода подтверждения импорта старых сейвов из 1.6.1. Сейв формата v1–v3 не содержит HMAC, и в 1.6.1 такой файл уже не применялся молча: загрузчик отказывал и запоминал его как ожидающий решения, а игра один раз спрашивала на активном языке, импортировать ли его в этот слот. Две проверки нашли, что отклонённый файл мог вернуться через резервную копию слота при обычной записи, а ответ, данный для одного файла, мог примениться к другим байтам, подменённым, пока диалог открыт.

Теперь `_store` доверяет предыдущему телу только из файла, который игрок только что подтвердил, а согласие привязано к SHA-256-дайджесту точного текста файла, по слотам: если байты изменились, пока шёл вопрос, ничего не применяется, а текущее тело остаётся ожидающим нового вопроса. Схема сейвов, слоты, автосохранение и железный режим не меняются; геймплей, баланс и графика не менялись. Звук: `purchase.wav` больше не дублирует `pickup.wav` (у покупки своё арпеджио), громкость музыки по умолчанию поднята с 0,30 до 0,65. Это доведение также добавляет недостающие заметки к патчу 1.6.2, доказательства приёмки, сертификат и отчёт, исправляет устаревшие метаданные версий и удаляет два пустых автозагружаемых скрипта, которые нигде не использовались.

Приёмка в этом доведении — исходный гейт на полной копии с Godot 4.7 Stable на Linux: импорт и строгий гейт предупреждений 105/105, Python-контракты 10/10, headless-прогон `run_tests.py` 79/79 кейсов, матрица механик 32×8=256 ячеек с `EXECUTED_PASS` на RU и EN. Отрисованный гейт, soak, нативные маршруты и дымовая проверка опубликованного бинаря для 1.6.2 не перезапускались — последние исполненные относятся к 1.6.1 (83 и 83 проверок на локаль, 3 петли за 2546 с, 5/5 маршрутов). Каталог — 811 ключей в каждой локали (в заметках 1.6.1 было ошибочно 810), тестовых GDScript-источников — 86.

## Published distribution receipt

None yet for 1.6.2. When published, record here: tag, tag commit, ZIP name and bytes, ZIP SHA256, sums file and SHA256, and the fresh-download `sha256sum -c` result with exit code. The owner checks in [HANDOFF](HANDOFF.md) remain outstanding before announcement.
