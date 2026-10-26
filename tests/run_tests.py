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
    parser.add_argument('--language', choices=['ru','en'], default='ru', help='QA display locale')
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
        environment['GAME_LANGUAGE'] = args.language
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
        cases.append(('credits', ['--headless', '--script', 'res://tests/test_credits.gd']))
        cases.append(('release-details', ['--headless', '--script', 'res://tests/test_release_details.gd']))
        cases.append(('disabled-explanations', ['--headless', '--script', 'res://tests/test_disabled_explanations.gd']))
        cases.append(('comfort-preferences', ['--headless', '--script', 'res://tests/test_comfort_preferences.gd']))
        cases.append(('live-world-locale', ['--headless', '--script', 'res://tests/test_live_world_locale.gd']))
        cases.append(('localized-feedback', ['--headless', '--script', 'res://tests/test_localized_feedback.gd']))
        cases.append(('locomotion-gait', ['--headless','--script','res://tests/test_locomotion_gait.gd']))
        cases.append(('settings-navigation', ['--headless','--script','res://tests/test_settings_navigation.gd']))
        cases.append(('initial-idle-pose', ['--headless','--script','res://tests/test_initial_idle_pose.gd']))
        cases.append(('map-navigation', ['--headless', '--script', 'res://tests/test_map_navigation.gd']))
        if args.rendered: cases.append(('road-landmarks', ['--resolution','1280x720','--script','res://tests/test_road_landmarks.gd']))
        cases.append(('localization', ['--headless', '--script', 'res://tests/test_localization.gd']))
        cases.append(('presentation', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_presentation.gd']))
        for case in ['identity', 'siege', 'civilians', 'combat_cover', 'terrain_sampling', 'weapon_view', 'house_cache', 'art_assets', 'movement_comfort', 'save_guard', 'legacy_migration', 'actor_material_lifetime', 'settings_bounds']:
            if (project / ('tests/test_' + case + '.gd')).exists():
                cases.append((case, ['--headless', '--script', 'res://tests/test_' + case + '.gd']))
        cases.append(('world-sky-lifetime', ([] if args.rendered else ['--headless']) + ['--resolution', '1280x720', '--script', 'res://tests/test_world_sky_lifetime.gd']))
        cases.append(('clear-play', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_clear_play.gd']))
        cases.append(('premium-ui', ([] if args.rendered else ['--headless']) + ['--resolution', '540x960' if portrait else '1280x720', '--script', 'res://tests/test_premium_ui.gd']))
        for case in ['detailed_figures','weapon_detail','campaign_finale','archer_presentation']:
            cases.append((case, ['--headless', '--script', 'res://tests/test_' + case + '.gd']))
        cases.append(('release-hardening', ['--headless', '--script', 'res://tests/test_release_hardening.gd']))
        cases.append(('music-transitions', ['--headless', '--script', 'res://tests/test_music_transitions.gd']))
        for case in ['ui_audio_feedback','context_audio']:
            cases.append((case, ['--headless', '--script', 'res://tests/test_' + case + '.gd']))
        for case in ['qa_router','build_integrity','critical_read_bounds','integrity_notice','save_recovery','atomic_economy']:
            cases.append((case, ['--headless','--script','res://tests/test_'+case+'.gd']))
        cases.append(('navigation-matrix', ([] if args.rendered else ['--headless'])+['--resolution', '1280x720' if not portrait else '540x960','--script','res://tests/test_navigation_matrix.gd']))
        cases.append(('qa-seed', ['--headless','--script','res://tests/test_qa_seed.gd']))
        cases.append(('mechanics-inputs', ['--headless','--script','res://tests/test_mechanics_inputs.gd']))
        cases.append(('profile-contract', ['--headless','--script','res://tests/test_profile_contract.gd']))
        cases.append(('army-pause-regression', ['--headless','--script','res://tests/test_army_pause_regression.gd']))
        cases.append(('army-casualty-lifetime', ['--headless','--script','res://tests/test_army_casualty_lifetime.gd']))
        cases.append(('iron-death-reentry', ['--headless','--script','res://tests/test_iron_death_reentry.gd']))
        cases.append(('companion-scan-regression', ['--headless','--script','res://tests/test_companion_scan_regression.gd']))
        cases.append(('exact-float-limits', ['--headless','--script','res://tests/test_exact_float_limits.gd']))
        cases.append(('save-float-precision', ['--headless','--script','res://tests/test_save_float_precision.gd']))
        cases.append(('invalid-combat-inputs', ['--headless','--script','res://tests/test_invalid_combat_inputs.gd']))
        cases.append(('untrusted-exploration', ['--headless','--script','res://tests/test_untrusted_exploration.gd']))
        cases.append(('packed-append-regression', ['--headless','--script','res://tests/test_packed_append_regression.gd']))
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
        contract = subprocess.run([sys.executable, str(project / 'tests/test_export_contract.py')], timeout=30)
        if contract.returncode: return contract.returncode
        copy_contract = subprocess.run([sys.executable, str(project / 'tests/test_copy_contract.py')], timeout=30)
        if copy_contract.returncode: return copy_contract.returncode
        promises = subprocess.run([sys.executable, str(project / 'tests/test_promise_matrix.py')], timeout=30)
        if promises.returncode: return promises.returncode
        mechanics = subprocess.run([sys.executable, str(project / 'tests/test_mechanics_matrix.py')], timeout=30)
        if mechanics.returncode: return mechanics.returncode
        isolation = subprocess.run([sys.executable, str(project / 'tests/test_repo_isolation.py')], timeout=30)
        if isolation.returncode: return isolation.returncode
        soundtrack = subprocess.run([sys.executable, str(project / 'tests/test_soundtrack.py')], timeout=60)
        if soundtrack.returncode: return soundtrack.returncode
        assets = subprocess.run([sys.executable, str(project / 'tests/test_audio_assets.py')], timeout=60)
        if assets.returncode:
            return assets.returncode
        for source_contract in ['test_public_qa_contract.py','test_release_export_tool.py','test_critical_manifest.py']:
            result=subprocess.run([sys.executable,str(project/'tests'/source_contract)],timeout=60)
            if result.returncode:return result.returncode
        for name, switches in cases:
            if name == 'regressions':
                strict = subprocess.run([sys.executable, str(project / 'tools/check_gdscript_warnings.py'), '--godot', args.godot, '--artifacts', str(artifacts / 'strict')], env=environment, timeout=300)
                if strict.returncode: return strict.returncode
            log_path = artifacts / (name + '.log')
            command = [args.godot, '--rendering-method', 'gl_compatibility', '--path', str(project), '--log-file', str(log_path), *switches]
            result = subprocess.run(command, env=environment, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600 if name.startswith('campaign-route-') or name=='release-hardening' else 180)
            log = log_path.read_text(encoding='utf-8', errors='replace') if log_path.exists() else 'ERROR: Missing Godot log'
            console = result.stdout + result.stderr
            (artifacts / (name + '-console.log')).write_text(console, encoding='utf-8')
            log += '\n' + console
            errors = [line for line in log.splitlines() if ('ERROR:' in line or 'FAIL:' in line or 'SCRIPT ERROR' in line) and 'Failed to read the root certificate store' not in line]
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
