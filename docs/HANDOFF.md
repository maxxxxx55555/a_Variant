# Marchland Oaths — owner handoff

> Announcement hold: the newer [ACCEPTANCE_CERTIFICATE.md](ACCEPTANCE_CERTIFICATE.md) records failed clean-tag source contracts. Earlier finite results below remain historical. The five manual checks cannot waive these mandatory blockers.

Accepted Windows release: [v1.5.1](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.1). Immutable game source: `006c164895d8d70fc2a72a61610b2ad27bb9e97e`. Post-tag closeout commits add documentation only; use the versioned release ZIP for play. [FINAL_REPORT.md](FINAL_REPORT.md) contains full hashes, F1–F8 acceptance, native guard output, soundtrack provenance and limitations.

## Five checks before announcement

1. **Download and check the exact files.** Download [MarchlandOaths-Windows-1.5.1.zip](https://github.com/maxxxxx55555/a_Variant/releases/download/v1.5.1/MarchlandOaths-Windows-1.5.1.zip) and [MarchlandOaths-SHA256SUMS-1.5.1.txt](https://github.com/maxxxxx55555/a_Variant/releases/download/v1.5.1/MarchlandOaths-SHA256SUMS-1.5.1.txt) into the same empty folder. In Git Bash, WSL/Linux or a shell providing `sha256sum`, run the command below. Keep the exact capitalization; do not rename either download. The closeout independently downloaded these public files and got the shown exit0 result.
2. **Extract and launch.** Extract the entire ZIP to a writable ordinary Windows folder and run `MarchlandOaths/MarchlandOaths.exe`. Keep its matching `.pck`, licenses and README together. Use a clean test profile for a new game. Public builds reject verifier flags even with `GAME_QA=1`; no private QA build/key is needed for normal play.
3. **Check presentation and audio.** Select English and Русский in settings, switch live and restart once to confirm persistence. Check window size, readable buttons, keyboard focus/Back and reduced motion. Set a comfortable Music level and personally listen to the four moods plus victory/defeat cues listed in FINAL_REPORT; verify Master/Music/SFX/UI controls independently and open Credits. Mood contexts are exploration, settlement, combat and war. Automated waveform/routing tests have passed; independent listening is not claimed.
4. **Check ordinary play and profile migration on copies.** Play a new session through key actions, save, close and Continue. Inspect victory and defeat presentation. Before opening an old installation, close both games and back up the entire profile directory below, including `save_integrity.key`, guard files and backups. Test a disposable copy of a valid protected 1.4.0 and 1.5.0 profile. Do not move only a save file or overwrite your only original copy. Existing1.4.0 and1.5.0 profiles were actually accepted in source and public native builds. Iron-mode defeat is intentionally terminal; normal paid recovery remains available.
5. **Review distribution and honest claims.** Keep credits, creator licenses and music terms with the build; verify the release page/download names before sharing. The portable EXE has no Authenticode signature, so Windows may show its normal unsigned-app warning. Complete an independent human play/listening session before a marketing announcement if that assurance is desired. Android/emulator and store certification, broad device coverage, universal zero bugs, invulnerability and AAA scale are outside this accepted Windows release.

```sh
sha256sum -c MarchlandOaths-SHA256SUMS-1.5.1.txt
```

Actual fresh-download closeout output:

```text
MarchlandOaths-Windows-1.5.1.zip: OK
exit: 0
```

ZIP SHA256: `8e392c3708d907790906d7c0b7a4794a3c987b507456f74b87831eae553a3b7d`.
Checksum-file SHA256: `fdd5675109e86824586cfe05eb690f47b5da061e6f0727305eaea47ea938ed81`.

Legacy profile directory (kept unchanged for compatibility):

```text
%APPDATA%/Godot/app_userdata/Oaths of the March
```

Back up the whole directory while the app is closed. Keep your installation key private. If a problem appears, record the version, Windows/GPU information and exact actions; retain the affected profile privately and avoid posting keys or personal paths publicly.

## What this handoff establishes

The finite accepted edition passed complete EN/RU suites (62 Godot invocations per locale plus Python contracts), 24 mechanics / 192 executed cells,50 complete distinct seeds, rendered soak, exact native wins/defeat, original protected-profile compatibility, public/private QA separation, critical-data tamper/read-only fallback, encrypted pack checks, license-byte/provenance checks and fresh public download checksums. Full tests were run before release; closeout reran only the requested download, native guards and API/isolation checks because no game files changed.

## Deliberate exclusions and preservation

Offline integrity cannot prevent a device owner from modifying code or extracting local keys. No independent extended human playtest or every-device/audio-hardware certification is asserted. Android is omitted under the accepted unavailable-emulator fallback. Private signing/build keys and QA executables are not included. Previously published tags, archives and source history remain unchanged.
