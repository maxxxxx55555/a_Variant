"""Generate the repository-authored 24 px line-icon set used by the interface.

Every icon shares a 24x24 viewBox, 2 px stroke, round joins and one consistent
corner language. The source paths live here so provenance and review can be
reproduced without a binary editor.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "ui" / "icons"

PATHS = {
    "inventory": '<path d="M4 9h16l-1.6 11H5.6z"/><path d="M8 9V7a4 4 0 0 1 8 0v2"/><path d="M12 13v3"/>',
    "potion": '<path d="M10 3h4"/><path d="M11 3v5l-5.2 9.2A2.2 2.2 0 0 0 7.7 21h8.6a2.2 2.2 0 0 0 1.9-3.8L13 8V3"/><path d="M8.3 15h7.4"/>',
    "food": '<path d="M5 14c0-4 3-7 7-7s7 3 7 7v3H5z"/><path d="M8 10l2 2M12 7v3M16 10l-2 2"/><path d="M4 20h16"/>',
    "diplomacy": '<path d="M5 21V4M5 4l7 2-7 2"/><path d="M19 21V9M19 9l-7 2 7 2"/>',
    "siege": '<path d="M5 21V8h4V4h2v4h2V4h2v4h2v13z"/><path d="M10 21v-5a2 2 0 0 1 4 0v5"/>',
    "objective": '<path d="M6 21V3"/><path d="M6 4h11l-2.5 3.5L17 11H6"/>',
    "codex": '<path d="M12 6C10 4 7 4 4 5v14c3-1 6-1 8 1 2-2 5-2 8-1V5c-3-1-6-1-8 1z"/><path d="M12 6v14"/>',
    "settings": '<path d="M4 7h16M4 17h16"/><circle cx="9" cy="7" r="2"/><circle cx="15" cy="17" r="2"/>',
    "sound": '<path d="M4 10v4h4l7 4V6l-7 4z"/><path d="M18 9a4 4 0 0 1 0 6"/>',
    "language": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c3 4 3 14 0 18"/>',
    "stats": '<path d="M4 20h16"/><path d="M6 20v-7M11 20V6M16 20v-9M21 20V4"/>',
    "credits": '<path d="M6 4h12v16H6z"/><path d="M9 8h6M9 12h6M9 16h4"/>',
    "continue": '<path d="M4 12h14"/><path d="M13 7l5 5-5 5"/>',
    "new_campaign": '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
    "save": '<path d="M5 19l4-1 10-10-3-3L6 15z"/><path d="M13 6l4 4M5 19h7"/>',
    "load": '<path d="M4 6h6l2 2h8v10H4z"/><path d="M8 12h8M8 15h5"/>',
    "exit": '<path d="M14 4H6v16h8"/><path d="M10 12h10M17 8l4 4-4 4"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "map": '<path d="M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2z"/><path d="M9 4v14M15 6v14"/>',
    "army": '<path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z"/><path d="M12 7v8"/>',
    "workshop": '<path d="M4 20l7-7"/><path d="M9 8l3-3 7 7-3 3z"/><path d="M6 6l3 3"/>',
    "journal": '<path d="M20 4c-6 1-10 4-13 9l-2 6 6-2c5-3 8-7 9-13z"/><path d="M7 17l5-5"/>',
    "town": '<path d="M3 20V10l5-3 5 3v10z"/><path d="M13 20V7h4v13M7 20v-4h4v4"/>',
    "road": '<path d="M4 21c5-4 2-8 7-11s1-6 9-8"/><path d="M7 17h3M12 10h3M17 5h3"/>',
    "explored": '<path d="M12 4l8 8-8 8-8-8z"/>',
    "player": '<path d="M12 5l7 14H5z"/>',
    "selection": '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="2"/>',
    "pause": '<path d="M9 5v14M15 5v14"/>',
    "quest": '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
    "faction": '<path d="M6 21V4M6 4l9 3-9 3"/><path d="M6 11l7 2-7 2"/>',
    "oath": '<circle cx="12" cy="10" r="5"/><path d="M9 14l-2 7 5-2 5 2-2-7"/>',
    "tier": '<path d="M12 3l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 16.4l-5.2 2.8 1-5.9-4.3-4.1 5.9-.8z"/>',
    "building_farm": '<path d="M4 21V9l8-5 8 5v12z"/><path d="M4 13h16M9 21v-5h6v5"/>',
    "building_housing": '<path d="M3 11l9-7 9 7"/><path d="M5 10v11h14V10M10 21v-6h4v6"/>',
    "building_infirmary": '<path d="M3 11l9-7 9 7"/><path d="M5 10v11h14V10M12 12v6M9 15h6"/>',
    "building_well": '<path d="M6 21V9h12v12M4 9h16M8 21v-4a4 4 0 0 1 8 0v4M12 9V5"/>',
    "building_market": '<path d="M4 10h16l-1 11H5z"/><path d="M6 10V6h12v4M8 14h8"/>',
    "building_sawmill": '<path d="M4 20h16M7 20l3-9M17 20l-3-9"/><path d="M8 8l4-5 4 5z"/>',
    "building_quarry": '<path d="M4 20l5-9 3 4 3-7 5 12z"/><path d="M9 15h6"/>',
    "building_forge": '<path d="M5 19h14M7 15h10l-1-4H8z"/><path d="M10 11V7h7l-1 4M13 4l2-1"/>',
    "building_barracks": '<path d="M6 21V10h12v11"/><path d="M9 21v-5h6v5M12 10V4l5 2-5 2"/>',
    "building_hall": '<path d="M3 21V12l9-6 9 6v9"/><path d="M7 21v-6h10v6M10 6h4"/><path d="M4 13h16"/>',
    "slot_head": '<path d="M5 16a7 7 0 0 1 14 0v4H5z"/><path d="M9 16v4M15 16v4M12 3v5"/>',
    "slot_torso": '<path d="M8 4L4 7l2 5 2-1v9h8v-9l2 1 2-5-4-3-4 3z"/><path d="M12 7v4"/>',
    "slot_legs": '<path d="M8 3v9l-2 9h5l1-9V3"/><path d="M16 3v9l2 9h-5l-1-9V3"/>',
    "slot_weapon": '<path d="M8 16L19 5l1-3-3 1L6 14z"/><path d="M4 20l3-3M6 14l4 4"/>',
}


def icon_svg(paths):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">'
        '<g fill="none" stroke="#e8dcc3" stroke-width="2" stroke-linecap="round" '
        'stroke-linejoin="round">' + paths + "</g></svg>\n"
    )


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    digests = {}
    for name, paths in PATHS.items():
        target = OUTPUT / (name + ".svg")
        target.write_text(icon_svg(paths), encoding="utf-8", newline="\n")
        digests[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    provenance = {
        "provider": "Repository-authored SVG line icons; no generated raster content",
        "tool": "tools/generate_ui_icons.py",
        "spec": "24x24 viewBox, 2 px stroke, round caps/joins, parchment #E8DCC3",
        "license": "CC0-1.0",
        "count": len(PATHS),
        "sha256": digests,
    }
    (OUTPUT / "provenance.json").write_text(
        json.dumps(provenance, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Generated {len(PATHS)} interface icons")


if __name__ == "__main__":
    main()
