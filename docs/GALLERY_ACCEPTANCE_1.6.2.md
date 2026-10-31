# Gallery acceptance — Marchland Oaths 1.6.2

1.6.2 changes no screen layout. The one surface it touches is the legacy import confirmation, whose behaviour was tightened: the answer now belongs to the exact bytes that were shown, prompts are per slot, and a second slot asking a question gets its own dialog instead of silently reusing the first one. These frames are that dialog re-rendered from the 1.6.2 tree, so the visual record matches the shipped bytes rather than the 1.6.1 ones.

## Captured frames

| File | What it shows |
| --- | --- |
| `docs/galleries/1.6.2/ru-1280x720-legacy-import-dialog.png` | «Старый формат сохранения» with the checksum-only explanation, «Импортировать» holding the focus ring, and «Не импортировать». |
| `docs/galleries/1.6.2/en-1280x720-legacy-import-dialog.png` | The same dialog in English: "Old save format", "This file predates signed profiles and is checked by checksum only. Import it into this slot?", "Import" focused, "Do not import". |

Capture method: `godot --rendering-method gl_compatibility --path . --resolution 1280x720 --script res://qa_tmp/dialog_capture.gd` with `GAME_GALLERY_DIR` and an isolated profile, driven by `qa_tmp/gallery_capture_1.6.2.py`. The script stages the shipped 1.1 fixture, proves the silent load is refused, opens the real dialog through `MarchTransition.confirm_legacy_import` and screenshots the live viewport — the frames are rendered by shipping code, not mockups. The capture driver `qa_tmp/dialog_capture.gd` is one-off release tooling kept outside the repository, so these frames are produced by the build machine rather than reproducible from a checkout alone; each frame is hashed in `docs/acceptance-1.6.2/visual-review.json`.

## Review

Both frames were inspected at native size. The wording is unchanged from 1.6.1 and is complete and unclipped in each language; the Russian body is the longer string and still fits the dialog at 1280×720. The accepted action carries the keyboard focus ring, and the dialog is the same themed `ConfirmationDialog` the game already uses for its unsaved-progress choice. No new visual defect was found in this edition, and none is claimed fixed here; the defects found in the 1.6.0 and 1.6.1 reviews are recorded in [GALLERY_ACCEPTANCE_1.6.0](GALLERY_ACCEPTANCE_1.6.0.md) and [GALLERY_ACCEPTANCE_1.6.1](GALLERY_ACCEPTANCE_1.6.1.md).

## Not pictured

The one new piece of copy is a notification for the case where the file changed after the question was asked («Файл был изменён после вашего ответа. Импорт не выполнен.» / "This file changed after you answered. Nothing was imported."). It is a transient toast emitted through `EventBus.notification_posted`, asserted by name in `tests/test_legacy_import.gd`, and it has no frame of its own here.

## Limits

These frames record the dialog's appearance and that it is reachable from real code. Whether the wording is clear enough for a player — including whether the dialog should name the slot it is asking about — is an owner judgement, listed in [HANDOFF](HANDOFF.md).
