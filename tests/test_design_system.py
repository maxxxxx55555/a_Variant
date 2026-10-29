"""Static design-system audit for Marchland Oaths 1.6.0.

Checks palette tokens, rarity colors, faction CVD separation, authored SVG
geometry and provenance hashes, typography, localization parity, symbol-free
UI copy and the art-direction deliverables. QA drivers cover runtime wiring.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []


def check(condition: bool, label: str) -> None:
    if not condition:
        FAILURES.append(label)
        print("FAIL:", label)


def load(relative: str):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]


def srgb_to_linear(channel: float) -> float:
    channel /= 255.0
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def luminance(value: str) -> float:
    red, green, blue = hex_to_rgb(value)
    return 0.2126 * srgb_to_linear(red) + 0.7152 * srgb_to_linear(green) + 0.0722 * srgb_to_linear(blue)


def contrast(a: str, b: str) -> float:
    light, dark = sorted((luminance(a), luminance(b)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


def linear_rgb(value: str) -> tuple[float, float, float]:
    red, green, blue = hex_to_rgb(value)
    return srgb_to_linear(red), srgb_to_linear(green), srgb_to_linear(blue)


def simulate(value: str, matrix: list[list[float]]) -> tuple[float, float, float]:
    red, green, blue = linear_rgb(value)
    return tuple(
        max(0.0, min(1.0, matrix[row][0] * red + matrix[row][1] * green + matrix[row][2] * blue))
        for row in range(3)
    )  # type: ignore[return-value]


def to_lab(rgb: tuple[float, float, float]) -> tuple[float, float, float]:
    red, green, blue = rgb
    x = (0.4124564 * red + 0.3575761 * green + 0.1804375 * blue) / 0.95047
    y = 0.2126729 * red + 0.7151522 * green + 0.0721750 * blue
    z = (0.0193339 * red + 0.1191920 * green + 0.9503041 * blue) / 1.08883

    def f(value: float) -> float:
        return value ** (1.0 / 3.0) if value > 0.008856 else 7.787 * value + 16.0 / 116.0

    fx, fy, fz = f(x), f(y), f(z)
    return 116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz)


def delta_e(a: str, b: str, matrix: list[list[float]] | None = None) -> float:
    if matrix is None:
        first, second = linear_rgb(a), linear_rgb(b)
    else:
        first, second = simulate(a, matrix), simulate(b, matrix)
    lab_a, lab_b = to_lab(first), to_lab(second)
    return math.sqrt(sum((lab_a[index] - lab_b[index]) ** 2 for index in range(3)))


PROTAN = [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]
DEUTAN = [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]
TRITAN = [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]]

EXPECTED_TOKENS = {
    "INK": "1e242a",
    "PANEL": "2a323a",
    "PANEL_DEEP": "171c21",
    "PARCHMENT": "e8dcc3",
    "DANGER": "b4534b",
    "BRASS": "c9a227",
    "CHALK": "dce3e9",
    "MIST": "91a0a7",
    "SAGE": "72968b",
    "FOCUS": "e8dcc3",
    "EDGE": "61717a",
}
EXPECTED_RARITY = {
    "common": "C8CDD2",
    "uncommon": "7FB069",
    "rare": "5B84C4",
    "epic": "9A6CC4",
    "legendary": "C9A227",
}
EXPECTED_FACTIONS = {
    "woodland_freeholders": "528034",
    "iron_guild": "639cc0",
    "borderland_watch": "83392f",
    "river_covenant": "9ce4de",
    "stone_circle": "cab080",
    "marsh_keepers": "342f5b",
    "sunfield_union": "f9e59c",
    "pass_clans": "ae8265",
}
REQUIRED_KEYS = [
    "flow.tip.3", "flow.tip.4", "flow.tip.5",
    "escalation.0", "escalation.1", "escalation.2", "escalation.3", "escalation.4", "escalation.5",
    "settlement.buildings", "tutorial.done", "tutorial.pending",
]
SYMBOL_RE = re.compile("[\U0001F000-\U0001FAFF\u2600-\u27BF\u2190-\u21FF\uFE0F\u25A0-\u25FF\u2B00-\u2BFF]")


def audit_tokens() -> None:
    source = (ROOT / "scripts/ui/MarchTheme.gd").read_text(encoding="utf-8")
    colors = dict(re.findall(r'const (\w+):Color = Color\("([0-9a-f]{6})"\)', source))
    hexes = dict(re.findall(r'const (\w+)_HEX:String = "([0-9A-F]{6})"', source))
    check(colors == EXPECTED_TOKENS, "MarchTheme exposes the 1.6.0 graphite/parchment token set")
    for name, value in hexes.items():
        check(colors.get(name) == value.lower(), f"{name}_HEX matches the runtime token")
    for token, foreground in [("CHALK", "DCE3E9"), ("PARCHMENT", "E8DCC3")]:
        check(contrast(foreground, "1E242A") >= 7.0, f"{token} copy keeps 7:1 on graphite")
        check(contrast(foreground, "2A323A") >= 7.0, f"{token} copy keeps 7:1 on panels")
    check(contrast("91A0A7", "2A323A") >= 4.5, "Mist secondary copy keeps 4.5:1 on panels")
    check(contrast("C9A227", "1E242A") >= 4.5, "Brass accents keep 4.5:1 on graphite")
    check(contrast("72968B", "2A323A") >= 3.5, "Sage support labels keep 3.5:1 on panels")

    loot = (ROOT / "scripts/ui/LootStyle.gd").read_text(encoding="utf-8")
    rarity = dict(re.findall(r'"(\w+)": Color\("([0-9A-F]{6})"\)', loot))
    check(rarity == EXPECTED_RARITY, "Loot rarity colors stay on the authored palette")

    campaign = load("data/balance/campaign.json")
    factions = {row["id"]: str(row["color"]).lstrip("#").lower() for row in campaign["factions"]}
    check(factions == EXPECTED_FACTIONS, "Campaign factions use the CVD-safe 1.6.0 palette")
    for label, matrix in [("protan", PROTAN), ("deutan", DEUTAN), ("tritan", TRITAN)]:
        minimum = min(
            delta_e(a, b, matrix)
            for index, a in enumerate(factions.values())
            for b in list(factions.values())[index + 1:]
        )
        check(minimum >= 12.0, f"Faction colors separate by at least Delta E 12 under {label}")


def audit_typography_and_motion() -> None:
    for font in ["GolosText.ttf", "Literata.ttf"]:
        check((ROOT / "assets/fonts" / font).stat().st_size > 10000, f"{font} ships a real font binary")
    for license_name in ["GolosText-OFL.txt", "Literata-OFL.txt"]:
        check((ROOT / "assets/fonts" / license_name).is_file(), f"{license_name} stays beside the font")
    theme = (ROOT / "scripts/ui/MarchTheme.gd").read_text(encoding="utf-8")
    check('font.variation_opentype = {0x77676874: weight}' in theme, "Heading and body weights drive the variable axis")
    check('font.opentype_features = {&"tnum": 1}' in theme, "Counters request tabular figures")
    check(theme.count("surface(state)") >= 1, "Buttons use the authored nine-slice surface family")
    check('theme.set_stylebox("focus",type,focus())' in theme, "Keyboard focus is themed globally")
    for background, edge in [("1e242a", "2a323a")]:
        check(contrast("dce3e9", background) >= 7.0, "Body copy clears 7:1")
        check(contrast("dce3e9", edge) >= 7.0, "Body copy clears 7:1 on panels")

    motion = (ROOT / "scripts/ui/UIMotion.gd").read_text(encoding="utf-8")
    values = {name: float(value) for name, value in re.findall(r"const (\w+):float=([0-9.]+)", motion)}
    check(values.get("HOVER_SCALE") == 1.02, "Hover scale stays at 1.02")
    check(values.get("DURATION") == 0.16, "Hover motion lasts 160 ms")
    check(values.get("REVEAL_DURATION") == 0.18, "Arrival reveal lasts 180 ms")
    check("SettingsManager.reduced_motion" in motion, "Reduced motion gates UI tweens")

    ui_files = sorted((ROOT / "scripts/ui").glob("*.gd"))
    themed = [path for path in ui_files if "ThemeRef" in path.read_text(encoding="utf-8")]
    icon_users = [path for path in ui_files if "IconView" in path.read_text(encoding="utf-8")]
    check(len(themed) >= 10, "At least ten screens share the design-token module")
    check(len(icon_users) >= 10, "At least ten screens use the authored icon family")
    legacy = ["ebd9ae", "bdc9cf", "b6c2c5", "a6b294", "1C2932", "172B30", "DFC692", "BD8A87"]
    offenders = []
    for path in ui_files:
        text = path.read_text(encoding="utf-8")
        offenders.extend(f"{path.name}:{token}" for token in legacy if token.lower() in text.lower())
    check(not offenders, "No screen keeps the retired palette tokens: " + ", ".join(offenders[:6]))

    finale = (ROOT / "scripts/ui/CampaignFinale.gd").read_text(encoding="utf-8")
    check("heading_font(700)" in finale and "IconView.apply" in finale, "Campaign finale joins the shared type and icon systems")


def audit_icons() -> None:
    directory = ROOT / "assets/ui/icons"
    files = sorted(directory.glob("*.svg"))
    check(len(files) == 46, "The authored icon family contains 46 vectors")
    icon_source = (ROOT / "scripts/ui/IconSet.gd").read_text(encoding="utf-8")
    names = re.findall(r'"([a-z_]+)"', re.search(r"const NAMES:Array\[String\]=\[(.*?)\]", icon_source, re.S).group(1))  # type: ignore[union-attr]
    check({path.stem for path in files} == set(names), "IconSet names every shipped SVG and nothing else")
    check(len(names) == len(set(names)), "Icon names stay unique")

    geometry_ok = True
    symbol_ok = True
    for path in files:
        try:
            svg = ET.parse(path).getroot()
        except ET.ParseError:
            geometry_ok = False
            continue
        if svg.get("width") != "24" or svg.get("height") != "24" or svg.get("viewBox") != "0 0 24 24":
            geometry_ok = False
        group = svg.find(".//{*}g")
        if group is None:
            geometry_ok = False
            continue
        if (
            group.get("fill") != "none"
            or group.get("stroke", "").lower() != "#e8dcc3"
            or group.get("stroke-width") != "2"
            or group.get("stroke-linecap") != "round"
            or group.get("stroke-linejoin") != "round"
        ):
            geometry_ok = False
        if svg.find(".//{*}text") is not None or svg.find(".//{*}image") is not None or svg.find(".//{*}filter") is not None:
            symbol_ok = False
        if any(node.tag.lower().endswith(("text", "image")) for node in svg.iter()):
            symbol_ok = False
    check(geometry_ok, "Every icon keeps a 24 px box, 2 px rounded parchment strokes")
    check(symbol_ok, "Icons contain no raster embeds, filters or baked text")

    provenance = load("assets/ui/icons/provenance.json")
    check(provenance.get("count") == 46, "Icon provenance counts all 46 files")
    check(provenance.get("license") == "CC0-1.0", "Icon provenance declares CC0-1.0")
    check("Repository-authored" in str(provenance.get("provider", "")), "Icon provenance states repository authorship")
    hashes: dict[str, str] = provenance.get("sha256", {})
    check(set(hashes) == {path.stem for path in files}, "Provenance has an entry for every icon")
    mismatched = [
        path.name for path in files
        if hashes.get(path.stem) != hashlib.sha256(path.read_bytes()).hexdigest()
    ]
    check(not mismatched, "Icon provenance hashes match the shipped bytes: " + ", ".join(mismatched[:5]))

    imports = list(directory.glob("*.svg.import"))
    check(len(imports) == len(files), "Every SVG owns a Godot import recipe")


def audit_localization() -> None:
    catalog = load("data/balance/localization.json")
    check(len(catalog) >= 806, "Compiled catalog carries every 1.6.0 string")
    broken = [
        key for key, row in catalog.items()
        if not isinstance(row, dict) or not str(row.get("ru", "")).strip() or not str(row.get("en", "")).strip()
    ]
    check(not broken, "Every catalog entry is bilingual: " + ", ".join(broken[:5]))
    for key in REQUIRED_KEYS:
        check(key in catalog, f"Shipped catalog contains {key}")
    symbols = [
        key for key, row in catalog.items()
        if any(SYMBOL_RE.search(str(value)) for value in row.values())  # type: ignore[union-attr]
    ]
    check(not symbols, "Interface copy uses words instead of symbol glyphs: " + ", ".join(symbols[:5]))

    missing_static: dict[str, list[str]] = {}
    for path in (ROOT / "scripts").rglob("*.gd"):
        for key in re.findall(r'get_string\("([^"]+)"', path.read_text(encoding="utf-8")):
            if key.endswith((".", "_")):
                continue
            if key not in catalog:
                missing_static.setdefault(key, []).append(path.name)
    check(not missing_static, "Every literal localization key resolves: " + ", ".join(list(missing_static)[:8]))

    offenders = []
    for folder, pattern in [("scripts", "*.gd"), ("scenes", "*.tscn")]:
        for path in (ROOT / folder).rglob(pattern):
            text = path.read_text(encoding="utf-8")
            if SYMBOL_RE.search(text):
                offenders.append(path.relative_to(ROOT).as_posix())
    check(not offenders, "Shipping UI and scenes avoid emoji and shape glyphs: " + ", ".join(offenders[:5]))


def audit_documentation() -> None:
    art = (ROOT / "docs/ART_DIRECTION.md").read_text(encoding="utf-8")
    for required in ["1.6.0", "#1E242A", "#E8DCC3", "#C9A227", "#B4534B", "Literata", "Golos", "CC0-1.0", "CVD", "Delta E", "reduced motion", "docs/galleries/1.6.0"]:
        check(required in art, f"Art direction documents {required}")
    gallery = ROOT / "docs/galleries/1.6.0"
    images = sorted(gallery.glob("*.png")) if gallery.is_dir() else []
    check(len(images) >= 20, "The 1.6.0 gallery ships both locales at both viewports")
    checklist = (ROOT / "docs/GALLERY_ACCEPTANCE_1.6.0.md").read_text(encoding="utf-8") if (ROOT / "docs/GALLERY_ACCEPTANCE_1.6.0.md").is_file() else ""
    for required in ["1280×720", "1920×1080", "RU", "EN", "reduced motion", "reason"]:
        check(required in checklist, f"Gallery checklist covers {required}")
    check(checklist.count("png") >= 20, "Gallery checklist references every captured screen")


def main() -> int:
    audit_tokens()
    audit_typography_and_motion()
    audit_icons()
    audit_localization()
    audit_documentation()
    if FAILURES:
        print("DESIGN SYSTEM RESULT: FAIL", len(FAILURES))
        return 1
    print("DESIGN SYSTEM RESULT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
