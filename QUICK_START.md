# Marchland Oaths1.5.1 — quick start

Download the Windows1.5.1 release, verify its ZIP SHA256, extract the entire archive and launch MarchlandOaths.exe. Keep the supplied data pack and licenses alongside it. This edition targets Windows x86_64.

Choose English or Russian, a save slot and difficulty in the title menu. Continue resumes the selected campaign; New campaign starts it. Iron mode makes death permanent. Move with WASD, look with the mouse; the in-game help lists combat, interaction and menu bindings. Settings offer separate audio levels, camera options, MSAA and reduced motion. Credits list asset origins.

Back up the entire closed-game profile before upgrading from1.4.0/1.5.0, including save_integrity.key and guard files. Existing profile folder names are unchanged. Ordinary death has paid recovery; an iron tombstone cannot be resumed.

For source play, open project.godot in Godot4.7 Stable and press F5. For automated checks use python tests/run_tests.py --godot <path> --rendered --language en --artifacts <new-log-folder>; repeat with ru. Encrypted export additionally requires a private matching template/key. No Android artifact is supplied in this edition. See docs/RELEASE_1.5.1.md and SAVE-INTEGRITY.md for scope and limits.
