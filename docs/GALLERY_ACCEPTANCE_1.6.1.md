# Gallery acceptance — Marchland Oaths 1.6.1

1.6.1 changes one visual surface: the confirmation that appears when a save from before signed profiles is offered for import. Everything else keeps the 1.6.0 visual record in `docs/galleries/1.6.0/`; no other screen was re-captured because no other pixels changed.

## Captured frames

| File | What it shows |
| --- | --- |
| `docs/galleries/1.6.1/ru-1280x720-legacy-import-dialog.png` | «Старый формат сохранения» with the checksum-only explanation, «Импортировать» holding the focus ring, and «Не импортировать». |
| `docs/galleries/1.6.1/en-1280x720-legacy-import-dialog.png` | The same dialog in English: "Old save format", "This file predates signed profiles and is checked by checksum only. Import it into this slot?", "Import" focused, "Do not import". |

Capture method: `godot --rendering-method gl_compatibility --path . --resolution 1280x720 --script res://qa_tmp/dialog_capture.gd` with `GAME_GALLERY_DIR` and an isolated profile. The script stages the shipped 1.1 fixture, proves the silent load is refused, opens the real dialog through `MarchTransition.confirm_legacy_import` and screenshots the live viewport — the frames are rendered by shipping code, not mockups.

## Review

Both frames were inspected at native size. The text is complete and unclipped in each language, the accepted action carries the keyboard focus ring, the dialog is the same themed `ConfirmationDialog` the game already uses for its unsaved-progress choice, and the wording names the actual risk instead of a generic warning. The Russian body is the longest string and fits the dialog without truncation at 1280×720.

## Limits

These frames record the dialog's appearance and that it is reachable from real code. Whether the wording is clear enough for a player is an owner judgement, listed in [HANDOFF](HANDOFF.md).
