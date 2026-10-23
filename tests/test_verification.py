import os
import csv

def test_localization():
    ru_keys = {}
    en_keys = {}

    with open('data/strings/ru.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            if row and row[0].strip():
                ru_keys[row[0].strip()] = row[1].strip()

    with open('data/strings/en.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            if row and row[0].strip():
                en_keys[row[0].strip()] = row[2].strip()

    assert set(ru_keys.keys()) == set(en_keys.keys()), f"Key mismatch! RU extra: {set(ru_keys.keys()) - set(en_keys.keys())}, EN extra: {set(en_keys.keys()) - set(ru_keys.keys())}"

    # Verify unit entries
    unit_keys = ['unit.militia_spear.name', 'unit.shield_swordsmen.name', 'unit.archers.name', 'unit.heavy_infantry.name']
    for uk in unit_keys:
        assert uk in ru_keys, f"Unit key missing in RU: {uk}"
        assert uk in en_keys, f"Unit key missing in EN: {uk}"

    # Verify faction entries
    faction_keys = ['faction.woodland_freeholders.name', 'faction.borderland_watch.name', 'faction.iron_guild.name']
    for fk in faction_keys:
        assert fk in ru_keys, f"Faction key missing in RU: {fk}"
        assert fk in en_keys, f"Faction key missing in EN: {fk}"

    print(f"✓ Localization key parity test passed ({len(ru_keys)} keys verified)")

def test_data_resources():
    tres_files = []
    for root, dirs, files in os.walk('data'):
        for file in files:
            if file.endswith('.tres'):
                tres_files.append(os.path.join(root, file))

    assert len(tres_files) > 0, "No .tres data files found in data/"

    for f in tres_files:
        assert os.path.exists(f), f"Data resource missing: {f}"
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            assert 'script = ExtResource' in content or 'type="Resource"' in content, f"Invalid format in {f}"
    print(f"✓ Data resources check passed ({len(tres_files)} resources verified in data/)")

def test_project_structure():
    required = [
        'project.godot',
        'scenes/world/test_location.tscn',
        'scenes/characters/player.tscn',
        'scenes/enemies/enemy.tscn',
        'scenes/ui/hud.tscn',
        'scenes/ui/inventory_ui.tscn',
        'scenes/ui/pause_menu.tscn',
        'scripts/autoload/GameState.gd',
        'scripts/autoload/SaveSystem.gd',
        'scripts/autoload/LocalizationManager.gd',
        'scripts/autoload/IntegrityLogger.gd',
        'scripts/autoload/UnitData.gd',
        'scripts/autoload/FactionData.gd',
        'scripts/systems/ArmySystem.gd',
        'scripts/systems/FactionSystem.gd',
        'scripts/systems/DiplomacySystem.gd'
    ]
    for r in required:
        assert os.path.exists(r), f"Required file missing: {r}"
    print(f"✓ Project structure verification passed ({len(required)} critical files present)")

if __name__ == '__main__':
    test_localization()
    test_data_resources()
    test_project_structure()
    print("\nALL VERIFICATION TESTS PASSED SUCCESSFULLY!")
