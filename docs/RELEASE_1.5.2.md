# Marchland Oaths 1.5.2

## English

Normal Exit, window close and guarded QA rejection now wait for actual audio playback disposal before terminating. Save failures retain Retry/Stay/Discard, repeated accepted dialog callbacks cannot write twice, and private verifier cleanup remains reusable. Source test drivers drain audio explicitly and the runner rejects resource-leak warnings.

This patch repairs source-build reproducibility. Critical JSON and the compiled integrity manifest now agree with the committed LF files, and interface sound provenance records the canonical generator bytes. Ordinary Git checkout tests cover both autocrlf settings without metadata overrides, and run in CI and the full source suite. Existing trust, tamper, replacement-manifest, protected-save and license checks remain enforced.

Gameplay, illustrations, music WAVs, save schema and edition scope are retained: 60 dependency-linked objectives, eight regions,14 towns,40 points of interest, companions, settlement management and diplomatic/military/mixed endings. Live RU/EN presentation with687 catalog keys, four mood compositions and two musical finales, independent audio levels, reduced motion, credits and protected1.4.0/1.5.0 profiles remain available. No previous public tag or asset was replaced.

Extract all of `MarchlandOaths-Windows-1.5.2.zip` and run `MarchlandOaths.exe`, keeping its PCK, notices and licenses beside it. Check the exact ZIP against `MarchlandOaths-SHA256SUMS-1.5.2.txt` with `sha256sum -c`. Back up the whole closed-game user-data directory, including its installation key, before upgrading. Private QA binaries and keys are not distributed.

Publication requires full rendered RU/EN source suites, real checkout/tamper/audio/license checks,50 seeded complete routes, measured normal soak, three native verifier victories plus defeat, original protected-save compatibility, encrypted public/QA pack audit, reviewed galleries and exact-head CI. The release gate and acceptance report record actual results; historical results are not substituted for this patch's mandatory fresh checks.

Limits: Windows x64 offline edition, unsigned portable EXE, no Authenticode or store certification. Android artifacts are omitted under the documented unavailable-emulator fallback. Rendering remains stylized indie art. Finite testing does not guarantee zero possible bugs or prevent a device owner from modifying an offline game. Five owner play/listening/download checks remain a final human sign-off.

## Русский

Выход через меню и закрытие окна теперь дожидаются освобождения аудио. Повторные сигналы подтверждения не дублируют сохранения; Retry/Stay/Discard и коды отказа QA сохранены. Проверки больше не пропускают предупреждения об утечках ресурсов.

Исправлена воспроизводимая сборка из обычного Git-checkout: манифест данных и происхождение интерфейсных звуков соответствуют исходным LF-байтам. Игровые правила, музыка и защищённые сохранения не меняются. Сохраняются русская и английская локализации и совместимость профилей1.4.0/1.5.0.

Новый регрессионный тест проверяет обычную материализацию Git при обоих значениях autocrlf, без локальных обходных правил; он включён в CI и полный набор тестов. Проверки подмены данных, манифеста и сохранений сохранены. Старые опубликованные теги и файлы не заменяются.

Распакуйте весь `MarchlandOaths-Windows-1.5.2.zip` и запустите `MarchlandOaths.exe`. Сверьте архив с `MarchlandOaths-SHA256SUMS-1.5.2.txt` командой `sha256sum -c`; перед обновлением скопируйте всю папку профиля с ключом установки. QA-сборки и ключи не распространяются.

Релиз публикуется только после полного гейта: RU/EN, маршруты победы/поражения, старые профили,50 полных посевов, измеренная нагрузка, аудит зашифрованных пакетов, галереи и CI. Фактические результаты находятся в отчёте приёмки. Windows x64, офлайн; EXE без Authenticode. Android не выпускается, масштаб AAA и отсутствие любых возможных ошибок не заявляются. Ручные проверки владельца остаются обязательными.
