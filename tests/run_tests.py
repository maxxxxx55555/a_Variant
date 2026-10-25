"""Run the real Godot project in an isolated save profile and reject engine errors."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--rendered', action='store_true', help='Run the playthrough with a real graphics device')
    parser.add_argument('--full-campaign', action='store_true', help='Also traverse and fight through both sixty-objective campaign routes')
    parser.add_argument('--artifacts', type=Path, help='Directory for logs and rendered screenshots')
    args = parser.parse_args()
    if not args.godot:
        parser.error('Set GODOT_BIN or pass --godot with the Godot 4.7 executable path')
    project = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='godot-gameplay-') as temporary:
        profile = Path(temporary)
        artifacts = (args.artifacts or profile / 'artifacts').resolve()
        artifacts.mkdir(parents=True, exist_ok=True)
        environment = os.environ.copy()
        environment['GAME_AUDIO_MUTED'] = '1'
        for variable, folder in [('APPDATA', 'roaming'), ('LOCALAPPDATA', 'local'), ('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
            path = profile / folder
            path.mkdir()
            environment[variable] = str(path)
        environment['GAME_SCREENSHOT'] = str(artifacts / (project.name + '.png'))
        portrait = 'GameManager' in (project / 'project.godot').read_text(encoding='utf-8')
        cases = [
            ('import', ['--headless', '--editor', '--import', '--quit']),
            ('regressions', ['--headless', '--script', 'res://tests/test_gameplay.gd']),
            ('playthrough', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_gameplay.gd', '--', '--playthrough']),
        ]
        cases.append(('presentation', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_presentation.gd']))
        for case in ['identity', 'siege', 'civilians', 'combat_cover', 'terrain_sampling', 'weapon_view', 'house_cache', 'art_assets', 'movement_comfort', 'save_guard', 'legacy_migration', 'actor_material_lifetime', 'settings_bounds']:
            if (project / ('tests/test_' + case + '.gd')).exists():
                cases.append((case, ['--headless', '--script', 'res://tests/test_' + case + '.gd']))
        cases.append(('clear-play', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_clear_play.gd']))
        cases.append(('premium-ui', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_premium_ui.gd']))
        for case in ['detailed_figures','weapon_detail','campaign_finale','archer_presentation']:
            cases.append((case, ['--headless', '--script', 'res://tests/test_' + case + '.gd']))
        cases.append(('release-hardening', ['--headless', '--script', 'res://tests/test_release_hardening.gd']))
        cases.insert(2, ('audio', ['--headless', '--script', 'res://tests/test_audio.gd']))
        if portrait:
            cases.append(('balance', ['--headless', '--script', 'res://tests/test_gameplay.gd', '--', '--balance']))
        else:
            for script in ['strategy', 'campaign']:
                if (project / ('tests/test_' + script + '.gd')).exists():
                    cases.append((script, ([] if args.rendered else ['--headless']) + ['--resolution', '1280x720', '--script', 'res://tests/test_' + script + '.gd']))
        if args.full_campaign:
            for route in ['diplomatic', 'military']:
                cases.append(('campaign-route-' + route, ['--headless', '--fixed-fps', '30', '--script', 'res://tests/test_campaign_routes.gd', '--'] + (['--military'] if route == 'military' else [])))
        verification = subprocess.run([sys.executable, str(project / 'tests/test_verification.py')], timeout=30)
        if verification.returncode:
            return verification.returncode
        assets = subprocess.run([sys.executable, str(project / 'tests/test_audio_assets.py')], timeout=60)
        if assets.returncode:
            return assets.returncode
        for name, switches in cases:
            log_path = artifacts / (name + '.log')
            command = [args.godot, '--rendering-method', 'gl_compatibility', '--path', str(project), '--log-file', str(log_path), *switches]
            result = subprocess.run(command, env=environment, timeout=600 if name.startswith('campaign-route-') else 180)
            log = log_path.read_text(encoding='utf-8', errors='replace') if log_path.exists() else 'ERROR: Missing Godot log'
            errors = [line for line in log.splitlines() if ('ERROR:' in line or 'FAIL:' in line) and 'Failed to read the root certificate store' not in line]
            print(f'{name}: ' + ('PASS' if result.returncode == 0 and not errors else 'FAIL'))
            for line in log.splitlines():
                if line.startswith(('RESULT:', 'PLAYTHROUGH', 'FAIL:', 'CAMPAIGN ROUTE RESULT:', 'CAMPAIGN RESULT:', 'STRATEGY RESULT:', 'AUDIO RESULT:')):
                    print(line)
            if result.returncode or errors:
                print(log)
                return 1
        if args.artifacts:
            print(f'Artifacts: {artifacts}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
