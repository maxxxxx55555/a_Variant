# Offline save integrity

This edition validates save types, bounds, finite numbers and shipped resource references before applying game state. Saves use bounded reads, atomic replacement, known-good backups and purpose-bound HMAC-SHA256 with a random per-installation key. Valid older profiles migrate once; protected slots reject unsigned downgrades. A valid authenticated backup replaces a rejected main file. A fresh write with no valid previous snapshot preserves the rejected file in a .rejected copy; no save data is executed.

This detects ordinary save editing and accidental corruption. It is not server-authoritative anti-cheat or unbreakable DRM: a device owner can inspect the key, restore an older full profile or modify the executable. There is no kernel driver, process scanner, account service, telemetry or hidden network dependency. These are offline single-player games; no claim of perfect security or zero bugs is made.

Back up the entire existing Godot user-data folder, including save_integrity.key and guard_*.lock, while the game is closed. Copying only a protected save to another installation is insufficient. Keep a separate backup before upgrading; migration preserves valid progress but an older executable does not understand the new protection. If a slot is damaged, the loader tries its authenticated known-good backup; iron mode deliberately does not roll back to a backup.

The local key is generated on the player's machine and is never distributed in the source or game archive. Report a reproducible fault with game version, actions and a copy of the affected profile; do not post personal file paths or profile contents publicly.

Cryptographic API: https://docs.godotengine.org/en/4.0/classes/class_crypto.html

Version 1.2.1 additionally checks nested runtime state and reports failed saves. Legacy item metadata is normalized from the shipped item catalog. Save protection is unchanged (schema 4 / configuration guard v1), so valid 1.2 profiles retain their keys and progress.
