# Marchland Oaths 1.6.0 — owner handoff

Release: Marchland Oaths 1.6.0 — Second Oath & Polish. Read [release notes](RELEASE_1.6.0.md), [acceptance](ACCEPTANCE_CERTIFICATE.md) and use the current [announcement kit](ANNOUNCE_KIT.md). This is a portable offline Windows x64 edition; Android and store submissions are omitted.

Five checks the automated gate cannot make for you:

1. **Play the Second Oath, don't read about it.** Finish any campaign route, accept the Second Oath panel and pick Клятва мира / Oath of Peace. Confirm a new siege is refused with a localized explanation, and that the carried oath banner and titles are printed in all three places they belong — the finale, the save-slot list and the credits. Then start a Third Oath with a different modifier and check the cycle counter and enemy pressure actually change.
2. **Look for the Codex in the world, not in a menu.** Play until at least three entries unlock on their own (a town, a bound region, a camp or assault) and confirm an unmet entry stays visibly locked. Unlock one entry, save, reload, and confirm the codex comes back with the same entries — codex state lives in the protected profile.
3. **Follow the tracker with the keyboard only.** Tab to the finale's controls with the Second Oath unavailable and confirm the Continue button still holds focus; then confirm the HUD objective, its distance readout, the compass needle, the map marker and the toast all describe the same objective in both languages, and that all five surfaces disappear together when you end the campaign.
4. **Judge the feel by ear and eye.** Land three hits on an enemy and confirm the hit-stop reads as a beat rather than a stutter, the damage number for a heavy blow is legible over bright weather, a rare pickup's chime is quieter than the music bed, and turning on reduced motion removes the freeze, the pop and the halo breathing without removing information.
5. **Grow a town and load an old one.** Raise a settlement to tier 2 and then tier 3 while watching the skyline change, and confirm the seasonal tint matches the weather. Separately, install a published 1.4.0 or 1.5.0 profile, load it, save it once, and keep the backup — the migration is one-way by design.

Also confirm the exact ZIP and sums filenames and that `sha256sum -c` reports OK with exit 0 before redistributing.

These owner checks are not claimed complete by the automated gate. After the release gate and these five checks, the game may be announced and distributed. Unsigned executable, finite testing and offline-integrity limits are explained in the certificate.

## Previous release

[Marchland Oaths 1.5.2](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.2) — tag commit `5246c58e36a6be347a5fb8e0c2704609608b72d4`, ZIP `MarchlandOaths-Windows-1.5.2.zip`, SHA256 `9149f4c1c44cda9da19213d0e8e2c760beac02b1093eba567900138a95fe615b`, gate 58/58, fresh remote `sha256sum -c` OK. Evidence: [acceptance-1.5.2/distribution.json](acceptance-1.5.2/distribution.json). That tag and its assets are immutable; earlier handoffs remain in git history.
