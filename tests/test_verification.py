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
    print(f"✓ Localization key parity test passed ({len(ru_keys)} keys verified)")

def test_data_resources():
    files = [
        'data/weapons/iron_sword.tres',
        'data/armors/leather_armor.tres',
        'data/potions/health_potion.tres'
    ]
    for f in files:
        assert os.path.exists(f), f"Data resource missing: {f}"
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            assert 'script = ExtResource' in content or 'type="Resource"' in content, f"Invalid format in {f}"
    print(f"✓ Data resources check passed ({len(files)} resources verified)")

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
        'scripts/autoload/IntegrityLogger.gd'
    ]
    for r in required:
        assert os.path.exists(r), f"Required file missing: {r}"
    print(f"✓ Project structure verification passed ({len(required)} critical files present)")

if __name__ == '__main__':
    test_localization()
    test_data_resources()
    test_project_structure()
    print("\nALL VERIFICATION TESTS PASSED SUCCESSFULLY!")
