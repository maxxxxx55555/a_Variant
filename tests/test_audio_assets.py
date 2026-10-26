"""Validate shipped WAV files without requiring NumPy or an audio device."""
from array import array
import json
import hashlib
import math
from pathlib import Path
import sys
import wave


def verify(project):
    folder = project / 'assets/audio'
    catalog = json.loads((folder / 'catalog.json').read_text(encoding='utf-8'))
    count = 0
    for group in ['music', 'sfx']:
        for name, entry in catalog[group].items():
            with wave.open(str(folder / entry['path']), 'rb') as source:
                assert source.getsampwidth() == 2, f'{name}: expected 16-bit PCM'
                assert source.getframerate() == 32000, f'{name}: unexpected sample rate'
                channels = source.getnchannels()
                assert channels == entry['channels']
                length = source.getnframes()
                assert length > 128, f'{name}: empty or truncated asset'
                samples = array('h', source.readframes(length))
            if sys.byteorder != 'little':
                samples.byteswap()
            assert len(samples) == length * channels, f'{name}: incorrect data length'
            peak = max(abs(min(samples)), abs(max(samples))) / 32768
            assert .02 < peak < .95, f'{name}: silent or clipping asset ({peak})'
            points = samples[::max(1, len(samples) // 32000)]
            rms = math.sqrt(sum((value / 32768) ** 2 for value in points) / len(points))
            assert .001 < rms < .5, f'{name}: unsuitable loudness ({rms})'
            if group == 'music':
                assert length / 32000 > 60, f'{name}: background repeats too frequently'
                assert rms < .12, f'{name}: background music should stay quiet'
                assert entry.get('source') == 'Google Gemini / Lyria', f'{name}: old soundtrack remains'
                provenance = json.loads((folder / 'music-provenance.json').read_text(encoding='utf-8'))
                assert hashlib.sha256((folder / entry['path']).read_bytes()).hexdigest() == provenance[entry['path']]['wav_sha256']
            if name in ['ui_focus', 'ui_error']:
                record = json.loads((folder / 'interface-provenance.json').read_text())[entry['path']]
                assert record['source'] == 'synthesized CC0' and record['license'] == 'CC0-1.0'
                assert entry.get('source') == 'synthesized CC0' and entry.get('license') == 'CC0-1.0'
                assert hashlib.sha256((folder / entry['path']).read_bytes()).hexdigest() == record['wav_sha256']
                assert hashlib.sha256((project / record['generator']).read_bytes()).hexdigest() == record['generator_sha256']
                assert .04 <= length / 32000 <= .25 and channels == 1 and not entry['loop']
            dc = sum(points) / len(points) / 32768
            assert abs(dc) < .012, f'{name}: DC offset ({dc})'
            if entry.get('loop'):
                seam = max(abs(samples[channel] - samples[-channels + channel]) for channel in range(channels)) / 32768
                assert seam < .035, f'{name}: discontinuous loop boundary ({seam})'
            else:
                assert max(abs(samples[channel]) for channel in range(channels)) < 64, f'{name}: abrupt attack'
                assert max(abs(samples[-channels + channel]) for channel in range(channels)) < 64, f'{name}: abrupt ending'
            count += 1
    print(f'AUDIO ASSETS PASS: {count} WAV assets; levels, data, loop seams and envelopes verified')


if __name__ == '__main__':
    verify(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1])
