# Marchland Oaths 1.6.1 — release report

Release URL: [Marchland Oaths 1.6.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.6.1). Runtime sources, both rendered suites and the exported binaries are from commit `c88a2a89a5f60febd87d68efae632c7db5ce9ea8`.

1.6.1 is a patch that closes one finding from the security review of 1.6.0. A save written before signed profiles (schema v1–v3) carries no HMAC, because that format predates it, and 1.6.0 applied such a file the moment it was read and then re-signed it as an authenticated v4 save. That made one path where forged state needed no key. Since 1.6.1 the file is refused until the player confirms the import for that slot, in the active language: confirming applies it and re-signs it under schema 4 with the per-slot lock, declining leaves it byte-identical. No gameplay, balance, art or audio file changed, and no save format changed.

## What was verified

| Area | Result | Evidence |
|---|---|---|
| The new refusal | PASS in both locales: silent load returns nothing and records exactly that file as pending | `tests/test_legacy_import.gd`, `acceptance-1.6.1/suite-ru/` and `suite-en/` |
| The confirmation | PASS: localized title, body and both actions; the accepted action holds keyboard focus | `tests/test_legacy_import.gd`, `docs/galleries/1.6.1/` |
| Confirmed import | PASS: restores the real 1.1 state and writes an authenticated schema 4 file | `tests/test_legacy_import.gd`, `tests/test_legacy_migration.gd` |
| Declined import | PASS: nothing is applied and the file is unchanged byte for byte | `tests/test_legacy_import.gd` |
| Existing slots | PASS: a checksum-only file is still refused in any slot holding authenticated progress | `tests/test_save_recovery.gd`, `tests/test_profile_contract.gd` |
| Whole suite | 83/83 RU and 83/83 EN rendered full-campaign cases | `acceptance-1.6.1/suites.json` |
| Executed matrix | 32 mechanics × 8 columns = 256 cells, `EXECUTED_PASS` in RU and EN | `acceptance/mechanics-execution-1.6.0.json` re-executed at this tree |
| Soak | 3 complete campaign loops in 2546 s of measured runtime, zero failures, zero aborts, zero deaths, identical object counts | `acceptance-1.6.1/soak.json` |
| Native builds | 5/5 routes on the exported QA and public binaries | `acceptance-1.6.1/native.json` |
| Export integrity | 4/4 artifacts, every critical digest matched after decryption | `acceptance-1.6.1/pack-audit.json` |
| Localization | 810 keys per locale (4 added), copy contract and compiled catalog | `tests/test_copy_contract.py`, `acceptance-1.6.1/contracts.json` |

## Performance against the recorded 1.6.0 figures

| Metric | 1.6.0 (recorded, `9c0c145`) | 1.6.1 (`c88a2a8`) | Change |
|---|---|---|---|
| Scene load | 7861 ms | 7254 ms | -7.72% |
| Frames per second | 60.02 | 60.08 | +0.10% |
| Draw calls | 356 | 356 | +0 |
| Primitives | 295509 | 295509 | +0 |

Medians of three runs per edition on the same Windows host. 1.6.1 changes no rendering, asset or scene code, so it is compared with the 1.6.0 medians rather than a re-created older worktree; the basis and every raw sample are in `acceptance-1.6.1/perf.json`. Load time on this machine moves by hundreds of milliseconds between sessions, so the load figure is a no-regression check, not a measurement of improvement.

## Artifacts

| Asset | Bytes | SHA256 |
|---|---|---|
| `MarchlandOaths.exe` | 252281128 | `4db12ce899fdb19148b3307b21a2549d3fb21ea44651c430978f21c479efa50f` |
| `MarchlandOaths.pck` | 181017884 | `ad3b39ea572871e0fc109a0efa8565b8084a8c6f8a6b06cd7a3d20aebba0c287` |

The public pack is directory- and file-encrypted; the private QA pack is never published. A stock Godot editor cannot mount the encrypted pack (`acceptance-1.6.1/pack-audit.json`). The `MarchlandOaths-Windows-1.6.1.zip` and `MarchlandOaths-SHA256SUMS-1.6.1.txt` digests are recorded in the published distribution receipt, because an archive cannot embed its own checksum.

## Open questions and limits

- The published Windows executables are not Authenticode signed; Windows shows its normal warning.
- The checks ran on one Windows host with an AMD integrated GPU and are not a human playtest or a listening review.
- This patch removes a silent injection path. It does not make offline integrity unbreakable: the installation key is readable by the device owner, and a patched binary is out of scope for any client-side protection.
- Whether the dialog wording is clear to a player is an owner judgement, listed in [HANDOFF](HANDOFF.md).
- The Ubuntu CI import step aborted intermittently in the engine allocator on 1.6.0 commits and passed on re-run; `docs/.gdignore` keeps documentation images out of that import.

## Русский

Marchland Oaths 1.6.1 — патч, закрывающий одно замечание из обзора безопасности версии 1.6.0. Сейв формата v1–v3 не содержит HMAC (этот формат появился раньше подписания), и в 1.6.0 такой файл применялся сразу при чтении, а первая запись переподписывала его как аутентифицированный v4: получался путь подмены состояния, для которого ключ установки вообще не требовался.

Теперь файл не применяется молча: загрузчик отказывает и запоминает только этот файл как ожидающий решения, игра один раз спрашивает на активном языке («Старый формат сохранения», «Импортировать» / «Не импортировать»). Согласение применяет состояние и сразу переподписывает файл схемой 4 с блокировкой слота; отказ ничего не применяет и оставляет файл байт-в-байт прежним — это проверяется тестом. Схема сейвов, слоты, автосохранение и железный режим не изменены; геймплей, баланс, графика и звук не менялись.

Приёмка: 83 и 83 отрисованных полнокампанейских проверок на локаль, исполненная матрица 32×8=256 ячеек в RU и EN, измеренный soak: 3 полные петли кампании за 2546 с, без утечек и осиротевших узлов, 5/5 маршрутов (три победы, железная смерть и отказ публичной сборки) маршрутов на экспортированных сборках, 4/4 из 4/4 зашифрованных артефактов, критические данные сверены с расшифрованным содержимым. Каталог — 810 ключей (добавлено 4), тестовых источников — 86.

## Published distribution receipt

[Marchland Oaths 1.6.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.6.1) — distribution assets `MarchlandOaths-Windows-1.6.1.zip` (478,396,417 bytes, SHA256 `845bc95693354f678c785524210f005cf2a57e50a9a49ab66c86f80d92648567`) and `MarchlandOaths-SHA256SUMS-1.6.1.txt` (99 bytes, SHA256 `3ea20674cc19235b72fa3b1e5b147355dc602d0e3b747f4fce786f150bf831d8`). `sha256sum --check` on the sums file reports OK (exit 0). The fresh download of the published assets and a boot of the downloaded executable are recorded in `acceptance-1.6.1/distribution.json`.
