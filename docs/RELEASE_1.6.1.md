# Marchland Oaths 1.6.1 — legacy save import needs a person

This patch changes one thing: how the game treats a save file from before authenticated profiles. It arrived from a security review of 1.6.0 rather than from a player report, and it does not touch gameplay, balance, art or audio.

## What changed

A v1–v3 save carries no HMAC because those formats predate save signing; it is verified by its published checksum. In 1.6.0 such a file was applied as soon as it was read, and the first write re-signed it as an authenticated v4 save. That meant a planted legacy file could inject state on a path that never needed the installation key.

Since 1.6.1 the same file is never applied silently:

- The loader refuses it and remembers only that this particular file is pending.
- The game asks once, in the active language, with the title "Old save format" and Import / Do not import actions: "This file predates signed profiles and is checked by checksum only. Import it into this slot?"
- Confirming reads the body, checks the checksum, applies the state and immediately re-signs it as an authenticated v4 save under the per-slot lock.
- Declining applies nothing and leaves the file byte-identical — the new test asserts the bytes are unchanged.
- The pre-existing per-slot guard still refuses a checksum-only file in any slot that already holds authenticated progress.

## Compatibility

Profiles published by 1.4.0 and 1.5.0 already carry the HMAC and load exactly as before, with safe defaults for the oath fields and a backup before the one-way migration. Only genuinely old v1–v3 files now need a single confirmation. Nothing is deleted, and no save format changed: schema 4, the five manual slots, autosave and iron rules are untouched.

## Verification

The exchange is asserted end to end in `tests/test_legacy_import.gd` for both locales: a silent load is refused, the pending entry names exactly that file, the dialog carries the localized title, body and both actions, confirming restores the real 1.1 state and re-signs it under schema 4, and declining leaves the file untouched. `tests/test_legacy_migration.gd` and `tests/test_oath_migration.gd` now exercise the same two-step path against the shipped 1.1 fixtures. Four localization keys were added, so each catalog holds 810 entries, and the test inventory is 86 sources.

The full gate was re-run at this tree: 83 rendered full-campaign cases in RU and 83 in EN (all passing, each log hashed in `acceptance-1.6.1/suites.json`), the executed 32×8 mechanics matrix in both locales, 3 complete campaign loops of measured soak in 2546 s with identical object counts, 5/5 native routes on the exported builds, and 2/2 — every critical data digest matched its decrypted payload, and a stock engine still cannot mount the encrypted pack.

## Honest limits

Windows x64 only, offline, Compatibility/OpenGL rendering, and the executable is not Authenticode signed. This change removes a silent state-injection path; it does not make the offline protection unbreakable — a device owner can still read the installation key or patch the binary. Automated checks are finite and are not a human playtest.

## Русский

Патч меняет только одно: обращение со старыми сейвами. Файл схемы v1–v3 не содержит HMAC (его формат появился до подписания сейвов) и проверяется контрольной суммой. В 1.6.0 такой файл применялся сразу при чтении, а первая запись переподписывала его как аутентифицированный v4 — то есть подставной легаси-файл мог внедрить состояние, вообще не требуя ключа установки.

Теперь так не происходит: загрузчик отказывает и запоминает только этот файл как ожидающий решения; игра один раз спрашивает на активном языке («Старый формат сохранения», действия «Импортировать» / «Не импортировать»). Согласение читает тело, проверяет контрольную сумму, применяет состояние и сразу переподписывает файл как аутентифицированный v4 с блокировкой слота. Отказ ничего не применяет и оставляет файл байт-в-байт прежним — это отдельно проверяется тестом. Прежняя защита слота по-прежнему отвергает легаси-файл там, где уже есть аутентифицированный прогресс.

Профили 1.4.0 и 1.5.0 загружаются как раньше: они уже подписаны. Схема сейвов, пять слотов, автосохранение и железный режим не меняются; ничего не удаляется. Проверка: `tests/test_legacy_import.gd` в обеих локалях, обновлённые тесты миграции, 810 ключей в каждом каталоге, 86 тестовых источников. Ограничения те же: только Windows x64, офлайн, без подписи, автотесты не заменяют ручной прогон.
