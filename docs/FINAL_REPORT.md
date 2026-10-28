# Marchland Oaths 1.5.2 — final release report

Release URL: [Marchland Oaths 1.5.2](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.2). Runtime source `6780cad9460a83559f891639f71ddd2672b21575`; source-suite commit `ef48b6a9b953e9aa427c6bb33b7d350da9f59778`.

Automated acceptance: EN 67/67, RU 67/67; 50/50 distinct complete seed routes; 3/3 consecutive native victories plus defeat; legacy read/write round-trips and tamper rejection; measured soak 2683.422s, 3 complete loops; 26 reviewed raw frames. Full receipts: [certificate](ACCEPTANCE_CERTIFICATE.md), [kit](ANNOUNCE_KIT.md), `acceptance-1.5.2/`.

Patch changes: canonical critical-data and audio-generator bytes, stable Windows localization CSV serialization where applicable, bounded audio teardown for normal/QA exits, safe retry handling and stricter leak detection. Runtime balance, music recordings, save schema and licensed assets are retained. Earlier failed source acceptance is preserved in historical evidence; these passes use repaired source.

A test-only scheduler correction now observes bounded tween completion; a simulated slow frame passes, and removing the stop callback still fails the single-voice assertion. Shipping runtime bytes are unchanged by this test correction.

## Music file checksums

| Mood/cue | Title | SHA256 |
|---|---|---|
| exploration | Stone Path to Dusk | `928d3e830ab86c2ef9a170658fd5405a7b883e1d5c90e3481ef93afdd21d5813` |
| settlement | Hearths Among the Hills | `78749767a35ed41dcf151579f2a92c3479b90a6672984eef70aac05ff61d0315` |
| combat | Steel and Rain | `f43353c344afffd1d4982dfeeb6ed55537cc5feec5ce1e7a623a01edf95ce921` |
| war | Standards at Dawn | `4e52901ed029631e514f0c2994fe2122492f9e428f14e5c1f791e68de6337ed3` |
| victory | Oaths Remembered | `1ccb20ebe5767031c1699ddf42d2cd7f87d29f8c2c429d6450ffa21b3c7608b2` |
| defeat | The Last Watch | `035c080389e01cf7dd2fb030a6f150e4afa6e41c97850fdfc0785641cdaa34ca` |

Known limitations: no human/audible final acceptance, Android/store certification or Authenticode; no AAA or universal no-bug/invulnerability claim. See HANDOFF. Final ZIP hashes and remote verification are recorded after publication.

## Published distribution receipt

[Marchland Oaths 1.5.2](https://github.com/maxxxxx55555/a_Variant/releases/tag/v1.5.2) — tag commit `5246c58e36a6be347a5fb8e0c2704609608b72d4`. Gate: 58/58 (100%). Fresh remote `sha256sum -c`: **OK, exit 0**.

ZIP: `MarchlandOaths-Windows-1.5.2.zip`

SHA256: `9149f4c1c44cda9da19213d0e8e2c760beac02b1093eba567900138a95fe615b`

Evidence: [acceptance-1.5.2/distribution.json](acceptance-1.5.2/distribution.json). This post-publication update changes documentation only; the tagged build and release assets are unchanged. The five owner checks remain outstanding before announcement.
