"""Execute every mechanics-matrix reference and write reproducible release evidence.

Each referenced source runs in an isolated save profile for every requested display locale.
The collector refuses to publish a passing report unless every matrix cell has a passing
execution in every locale, so docs/MECHANICS_MATRIX.json can claim EXECUTED_PASS honestly.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE_ERRORS = ['ERROR:', 'FAIL:', 'SCRIPT ERROR', 'objectdb instances leaked',
                 'objectdb instances were leaked', 'orphan nodes detected',
                 'resources still in use at exit', 'were leaked at exit',
                 'rid allocations were leaked']

# A referenced source that is not itself a runnable entry point, mapped to the case that runs it.
ENTRY_POINTS = {
    'tests/MechanicsRoute.gd': ('tests/test_mechanics_route.gd', ['--fixed-fps', '30']),
}
# Additional argument sets for sources whose matrix cells cite more than one published mode.
EXTRA_MODES = {
    'tests/test_gameplay.gd': ([['--', '--playthrough']], 'playthrough'),
}
TIMEOUTS = {'tests/test_release_hardening.gd': 900, 'tests/test_gameplay.gd': 600,
            'tests/test_mechanics_route.gd': 900, 'tests/test_campaign.gd': 600,
            'tests/test_strategy.gd': 600, 'tests/test_navigation_matrix.gd': 600}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def referenced_paths(matrix: dict) -> list[str]:
    found = set()
    for row in matrix['rows']:
        for column in row['cells'].values():
            for cell in column:
                found.add(cell['path'])
    return sorted(found)


def error_lines(log: str) -> list[str]:
    return [line for line in log.splitlines()
            if any(marker in line for marker in ENGINE_ERRORS)
            and 'Failed to read the root certificate store' not in line]


def run_case(godot: str, reference: str, mode: str, switches: list[str], locale: str,
             logs: Path) -> dict:
    entry = Path(ENTRY_POINTS.get(reference, (reference, []))[0])
    prefix = list(ENTRY_POINTS.get(reference, (reference, []))[1])
    name = (entry.stem + ('-' + mode if mode else '') + '-' + locale).replace('__', '_')
    with tempfile.TemporaryDirectory(prefix='marchland-evidence-') as temporary:
        profile = Path(temporary)
        environment = os.environ.copy()
        environment['GAME_AUDIO_MUTED'] = '1'
        environment['GAME_LANGUAGE'] = locale
        for variable, folder in [('APPDATA', 'roaming'), ('LOCALAPPDATA', 'local'),
                                 ('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'),
                                 ('XDG_CACHE_HOME', 'cache')]:
            path = profile / folder
            path.mkdir()
            environment[variable] = str(path)
        if entry.suffix == '.py':
            command = [sys.executable, str(ROOT / entry)]
        else:
            command = [godot, '--headless', '--audio-driver', 'Dummy', '--rendering-method',
                       'gl_compatibility', '--path', str(ROOT), *prefix,
                       '--script', 'res://' + entry.as_posix(), *switches]
        timeout = TIMEOUTS.get(entry.as_posix(), 300)
        try:
            result = subprocess.run(command, env=environment, capture_output=True, text=True,
                                    encoding='utf-8', errors='replace', timeout=timeout)
            log = (result.stdout or '') + (result.stderr or '')
        except subprocess.TimeoutExpired as expired:
            log = ((expired.stdout or b'').decode('utf-8', 'replace') if isinstance(expired.stdout, bytes)
                   else (expired.stdout or '')) + '\nTIMEOUT after ' + str(timeout) + 's'
            result = None
        (logs / name).write_text(log, encoding='utf-8', newline='\n')
        failures = error_lines(log)
        status = 'PASS' if result is not None and result.returncode == 0 and not failures else 'FAIL'
        return {'case': name, 'entry': entry.as_posix(), 'switches': switches,
                'locale': locale, 'status': status,
                'exit_code': None if result is None else result.returncode,
                'timeout_s': timeout,
                'log': 'logs/' + name, 'log_sha256': digest(logs / name),
                'engine_errors': failures[:8]}


def running_godot() -> list[str]:
    """Godot command lines alive right now that point at this project tree. A second engine
    churning our .godot import cache makes the running game drop to read-only safe mode, so every
    save in the collector would fail and the report would publish that as product failure.
    Only command lines naming this absolute root count as contention: another project's engine
    touches a different cache and must never block this one."""
    if os.name != 'nt':
        return []
    query = ("Get-CimInstance Win32_Process -Filter \"Name='godot.exe'\" "
             '| Select-Object -ExpandProperty CommandLine')
    found = subprocess.run(['powershell', '-NoProfile', '-Command', query],
                           capture_output=True, text=True).stdout
    ours = (str(ROOT), ROOT.as_posix())
    return [line.strip() for line in found.splitlines()
            if line.strip() and any(form in line for form in ours)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN')
                        or shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--out', type=Path, default=ROOT / 'docs/acceptance/mechanics-execution-1.6.0')
    parser.add_argument('--locales', default='ru,en')
    parser.add_argument('--report-name', default='mechanics-execution-1.6.0.json')
    parser.add_argument('--allow-concurrent', action='store_true',
                        help='collect even while another Godot run is open on this project tree')
    options = parser.parse_args()
    if not options.godot:
        parser.error('Set GODOT_BIN or pass --godot with the Godot 4.7 executable path')
    if not options.allow_concurrent:
        contending = running_godot()
        if contending:
            parser.error('another Godot run is open on this project; its import-cache writes force '
                         'the game into read-only safe mode and would falsify the evidence. '
                         'Wait for it, or pass --allow-concurrent:\n  '
                         + '\n  '.join(contending[:4]))
    matrix = json.loads((ROOT / 'docs/MECHANICS_MATRIX.json').read_text(encoding='utf-8'))
    locales = [value.strip() for value in options.locales.split(',') if value.strip()]
    out = options.out.resolve()
    logs = out / 'logs'
    logs.mkdir(parents=True, exist_ok=True)
    for stale in logs.glob('*'):
        stale.unlink()
    engine = subprocess.run([options.godot, '--version'], capture_output=True, text=True).stdout.strip()
    commit = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True,
                            text=True).stdout.strip()
    executions = {}
    for reference in referenced_paths(matrix):
        modes = [('', [])]
        if reference in EXTRA_MODES:
            published, label = EXTRA_MODES[reference]
            for index, switches in enumerate(published):
                modes.append((label if len(published) == 1 else label + str(index), switches))
        per_locale = {}
        for locale in locales:
            per_locale[locale] = [run_case(options.godot, reference, mode, switches, locale, logs)
                                  for mode, switches in modes]
            print(reference, locale, *[record['status'] for record in per_locale[locale]], sep=' ')
        executions[reference] = {'source_sha256': digest(ROOT / reference), 'runs': per_locale}
    columns = matrix['columns']
    uncovered = []
    for row in matrix['rows']:
        for column in columns:
            options_by_column = [record['path'] for record in row['cells'][column]]
            proven = all(any(all(run['status'] == 'PASS' for run in executions[path]['runs'].get(locale, []))
                            for path in options_by_column) for locale in locales)
            if not proven:
                uncovered.append(row['mechanic'] + ' / ' + column)
    failures = sorted({reference for reference, record in executions.items()
                       for locale, runs in record['runs'].items() for run in runs
                       if run['status'] == 'FAIL'})
    report = {
        'schema': 1,
        'title': 'Marchland Oaths 1.6.0 mechanics matrix execution evidence',
        'engine': engine,
        'commit_under_test': commit,
        'display_locales': locales,
        'references': executions,
        'cells_total': len(matrix['rows']) * len(columns),
        'cells_without_passing_execution': uncovered,
        'failing_references': failures,
        'limits': 'Headless Compatibility GL runs with the Dummy audio driver in throwaway save profiles. '
                  'This records executable evidence for the mapped matrix cells; it does not replace a '
                  'human play session, an exported build smoke test, or a published binary check.',
    }
    (out.parent / options.report_name).write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n',
                                                 encoding='utf-8', newline='\n')
    if failures or uncovered:
        print('MECHANICS EXECUTION EVIDENCE: FAIL uncovered_cells=' + str(len(uncovered))
              + ' failing=' + str(len(failures)))
        for item in uncovered[:20]:
            print('UNCOVERED CELL: ' + item)
        return 1
    print('MECHANICS EXECUTION EVIDENCE: PASS references=' + str(len(executions))
          + ' locales=' + ','.join(locales) + ' cells=' + str(report['cells_total']))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
