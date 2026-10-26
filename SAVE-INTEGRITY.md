# Offline save integrity

This edition validates save types, bounds, finite numbers and shipped resource references before applying game state. Saves use bounded reads, atomic replacement, known-good backups and purpose-bound HMAC-SHA256 with a random per-installation key. Valid older profiles migrate once; protected slots reject unsigned downgrades. A valid authenticated backup replaces a rejected main file. A fresh write with no valid previous snapshot preserves the rejected file in a .rejected copy; no save data is executed.

This detects ordinary save editing and accidental corruption. It is not server-authoritative anti-cheat or unbreakable DRM: a device owner can inspect the key, restore an older full profile or modify the executable. There is no kernel driver, process scanner, account service, telemetry or hidden network dependency. These are offline single-player games; no claim of perfect security or zero bugs is made.

Back up the entire existing Godot user-data folder, including save_integrity.key and guard_*.lock, while the game is closed. Copying only a protected save to another installation is insufficient. Keep a separate backup before upgrading; migration preserves valid progress but an older executable does not understand the new protection. If a slot is damaged, the loader tries its authenticated known-good backup; iron mode deliberately does not roll back to a backup.

The local key is generated on the player's machine and is never distributed in the source or game archive. Report a reproducible fault with game version, actions and a copy of the affected profile; do not post personal file paths or profile contents publicly.

Cryptographic API: https://docs.godotengine.org/en/4.0/classes/class_crypto.html

Version 1.2.1 additionally checks nested runtime state and reports failed saves. Legacy item metadata is normalized from the shipped item catalog. Save protection is unchanged (schema 4 / configuration guard v1), so valid 1.2 profiles retain their keys and progress.

## V2 release boundary

BuildIntegrity runs before model autoloads. tools/build_manifest.py deterministically generates data/critical-manifest.json and a compiled TrustedData snapshot/root from every shipping data JSON and the audio catalog. Export preflight checks that both generated files match reviewed sources; it never silently blesses a modified installation. Startup verifies the manifest against its compiled SHA256 and every data entry. A mismatch logs the affected paths, presents EN/RU feedback and uses immutable trusted fallback content. Save/key creation, backup copies, repair, migration, settings writes and progress deletion are disabled in this safe mode; existing authentic progress remains readable. Only integrity.log may be written. This is corruption/modification detection, not external attestation of the executable.

A rejected protected primary is recovered only from a valid authenticated backup, with a localized message and a bounded local log containing no key or HMAC value. If neither copy is valid, the loader rejects the profile and says so. Unchanged valid save-load-save round trips retain a stable file hash. Purpose domains, install-key bytes and legacy user-data aliases remain unchanged.

Public Windows exports physically exclude private verifier resources. QA requires both a separate compiled custom feature and GAME_QA=1. Release templates omit console wrappers, debugger support and path overrides. Every PCK entry and the directory are encrypted. The build key is supplied only through the environment and a separately compiled matching custom template; neither private keys nor private QA builds belong in public artifacts. A stock engine or the other build key cannot mount the encrypted pack. A device owner can still reverse engineer a native binary or inspect memory; encryption is not DRM and this edition claims no prevention of all possible cheats.

Crafting, potion brewing, building and trade protect their synchronous debit/credit boundary against reentry and save/load callbacks. Save/load is refused inside a transaction and succeeds after its complete result. Invalid, negative, nonfinite or excessive resource balances/costs are rejected before payment; credited trade stockpiles cannot exceed the save policy's1e12 bound. Potion counts remain positive and at most10,000 per stack. Unchanged authentic schema4 saves preserve their existing timestamp/envelope rather than rewriting them, with normalized numeric state for canonical comparison. Iron-mode tombstones still cannot roll back to a backup.

Critical JSON, generated trust source and Python tooling have explicit LF checkout rules in .gitattributes. Fresh Windows checkouts therefore preserve the reviewed trust bytes with core.autocrlf enabled; creator-license byte rules are retained. test_critical_manifest.py rejects a missing checkout policy.

Startup caps the manifest at64KiB and each critical data file at8MiB before reading content; SHA256 uses64KiB streaming chunks. Oversized or unreadable content enters the same read-only safe mode instead of allocating arbitrary input size. Integrity dialogs use this game's own theme and update immediately with a language change.
