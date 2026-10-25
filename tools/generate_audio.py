"""Original deterministic audio assets. Requires NumPy; playback does not.

All compositions and synthesized effects produced by this script are dedicated
to the public domain under CC0-1.0. This generator now preserves separately supplied Gemini music and regenerates only synthesized effects when music-provenance.json is present.
"""
from pathlib import Path
import argparse
import json
import wave
import numpy as np

RATE = 32000
RNG = np.random.default_rng(2447)


def frequency(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def envelope(length, attack=0.012, release=0.14):
    result = np.ones(length)
    a, r = min(int(attack * RATE), length // 2), min(int(release * RATE), length // 2)
    if a:
        result[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if r:
        result[-r:] = np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return result


def voice(note, duration, instrument):
    length = max(4, int(duration * RATE))
    t = np.arange(length) / RATE
    f = frequency(note)
    if instrument == 'pluck':
        sound = sum(np.sin(2 * np.pi * f * harmonic * t) * np.exp(-t * (1.9 + harmonic * .65)) / harmonic ** 1.6 for harmonic in range(1, 9))
        env = envelope(length, .004, .18)
    elif instrument == 'bell':
        sound = sum(np.sin(2 * np.pi * f * harmonic * t) * np.exp(-t * decay) * level for harmonic, decay, level in [(1, 2.2, 1), (2.004, 3.5, .28), (4.01, 5, .06)])
        env = envelope(length, .008, .12)
    elif instrument == 'flute':
        phase = 2 * np.pi * f * t + .012 * np.sin(2 * np.pi * 4.8 * t)
        sound = np.sin(phase) + .13 * np.sin(2 * phase) + .035 * RNG.standard_normal(length)
        env = envelope(length, .12, .22)
    elif instrument == 'bass':
        sound = np.sin(2 * np.pi * f * t) + .16 * np.sin(4 * np.pi * f * t)
        env = envelope(length, .025, .2)
    else:
        sound = .5 * np.sin(2 * np.pi * f * .9991 * t) + .5 * np.sin(2 * np.pi * f * 1.0009 * t) + .12 * np.sin(4 * np.pi * f * t)
        env = envelope(length, min(.55, duration / 4), min(.7, duration / 4))
    return sound * env


def add(buffer, samples, start, amplitude=1.0, pan=0.0):
    """Circular placement retains tails across the boundary of a music loop."""
    indices = (np.arange(len(samples)) + int(start * RATE)) % len(buffer)
    levels = np.array([np.sqrt((1 - pan) / 2), np.sqrt((1 + pan) / 2)])
    np.add.at(buffer, indices, samples[:, None] * levels * amplitude)


def drum(duration=.7, heavy=False):
    t = np.arange(int(duration * RATE)) / RATE
    phase = 2 * np.pi * (44 * t + (20 if heavy else 10) * .08 * (1 - np.exp(-t / .08)))
    body = np.sin(phase) * np.exp(-t * (6 if heavy else 9))
    skin = RNG.standard_normal(len(t)) * np.exp(-t * 45) * .12
    return (body + skin) * envelope(len(t), .003, .1)


def compose(profile, mood):
    tempo = {'study': 78, 'career': 86, 'tycoon': 94, 'welcome': 72,
             'exploration': 72, 'settlement': 84, 'combat': 108, 'war': 96}[mood]
    beat = 60 / tempo
    bars = 8
    duration = bars * 4 * beat
    result = np.zeros((round(duration * RATE), 2), dtype=np.float64)
    corporate = profile == 'forbes'
    roots = [48, 45, 41, 43, 48, 45, 41, 43] if corporate else [45, 41, 48, 43, 45, 41, 43, 40]
    major_roots = {48, 41, 43} if corporate else {41, 48, 43}
    melody = [12, 19, 16, 14, 12, 7, 9, 7] if corporate else [12, 19, 15, 14, 12, 10, 7, 3]
    for bar, root in enumerate(roots):
        start = bar * 4 * beat
        third = 4 if root in major_roots else 3
        chord = [root, root + third, root + 7, root + 11 if corporate else root + 12]
        for index, note in enumerate(chord):
            add(result, voice(note + 12, beat * 4.6, 'pad'), start, .085 if corporate else .09, (index - 1.5) * .34)
        add(result, voice(root - 12, beat * 1.7, 'bass'), start, .18)
        add(result, voice(root - 12, beat * 1.3, 'bass'), start + 2 * beat, .14)
        for eighth in range(8):
            if mood in ['welcome', 'exploration'] and eighth % 2:
                continue
            note = chord[eighth % len(chord)] + 12
            add(result, voice(note, beat * 1.8, 'bell' if corporate else 'pluck'), start + eighth * beat / 2, .09 if corporate else .15, -.35 if eighth % 2 else .35)
        if bar % 2 == 0:
            for j in range(3):
                add(result, voice(root + melody[(bar + j) % len(melody)], beat * 1.5, 'bell' if corporate else 'flute'), start + (j + .25) * beat, .075 if corporate else .1, .12)
        if mood in ['career', 'tycoon', 'settlement', 'combat', 'war']:
            for hit in [0, 2, 3.5] if mood in ['combat', 'war'] else [0, 2]:
                add(result, drum(heavy=mood in ['combat', 'war']), start + hit * beat, .22 if mood in ['combat', 'war'] else .09)
            for hit in range(8):
                length = int(.09 * RATE)
                noise = RNG.standard_normal(length)
                noise -= np.roll(noise, 1)
                tick = noise * np.exp(-np.arange(length) / RATE * 70) * envelope(length, .002, .025)
                add(result, tick, start + hit * beat / 2, .024, -.3 if hit % 2 else .3)
        if mood == 'war':
            for note in [root, root + 7]:
                add(result, voice(note, beat * 3.7, 'flute'), start, .12, .25)
    # Gentle stereo echoes. Circular delays maintain a continuous loop.
    dry = result.copy()
    for fraction, level in [(.375, .17), (.75, .1), (1.5, .06)]:
        result += np.roll(dry[:, ::-1], round(beat * fraction * RATE), axis=0) * level
    return result


def effect(name):
    length = {'victory': 2.8, 'defeat': 2.2, 'upgrade': 1.1, 'potion': .65,
              'enemy_death': .9, 'ambience_forest': 16, 'ambience_camp': 16}.get(name, .38)
    n = int(length * RATE)
    t = np.arange(n) / RATE
    noise = RNG.standard_normal(n)
    if name.startswith('ambience_'):
        spectrum = np.fft.rfft(noise)
        hz = np.fft.rfftfreq(n, 1 / RATE)
        spectrum *= 1 / np.sqrt(1 + (hz / 320) ** 4)
        sound = np.fft.irfft(spectrum, n)
        sound *= .55 + .2 * np.sin(2 * np.pi * t / 4) + .15 * np.cos(2 * np.pi * t / 8)
        if name == 'ambience_camp':
            for _ in range(32):
                index = int(RNG.integers(0, n - 800))
                sound[index:index + 800] += noise[index:index + 800] * np.exp(-np.arange(800) / 110) * .6
        return sound
    if name.startswith('footstep_'):
        material = name.split('_')[1]
        tint = {'grass': .18, 'dirt': .3, 'stone': .7, 'wood': .5, 'snow': .12}.get(material, .3)
        smooth = np.convolve(noise, np.ones(7) / 7, mode='same')
        sound = smooth * np.exp(-t * 24) * .65 + noise * np.exp(-t * 42) * tint
        sound += np.sin(2 * np.pi * (90 if material != 'wood' else 180) * t) * np.exp(-t * 24) * .25
    elif name in ['swing', 'attack']:
        smooth = np.convolve(noise, np.ones(5) / 5, mode='same')
        sound = (smooth + .12 * np.sin(2 * np.pi * (180 * t + 320 * t ** 2))) * np.sin(np.pi * t / length) ** 3
    elif name in ['hit_metal', 'block']:
        sound = sum(np.sin(2 * np.pi * hz * t) * np.exp(-t * decay) * amp for hz, decay, amp in [(720, 12, .4), (1163, 16, .3), (1887, 20, .18), (2621, 28, .1)])
        sound += noise * np.exp(-t * 75) * .35
    elif name in ['hit', 'hit_flesh', 'enemy_hurt']:
        sound = noise * np.exp(-t * 31) * .55 + np.sin(2 * np.pi * 85 * t) * np.exp(-t * 18) * .5
    elif name == 'potion':
        sound = np.zeros(n)
        for onset, hz in [(0, 440), (.12, 520), (.25, 680), (.4, 820)]:
            offset = int(onset * RATE)
            local_t = t[:n - offset]
            sound[offset:] += np.sin(2 * np.pi * (hz * local_t + 35 * local_t ** 2)) * np.exp(-local_t * 18) * .3
        sound += np.convolve(noise, np.ones(12) / 12, mode='same') * np.sin(np.pi * t / length) ** 2 * .12
    elif name in ['victory', 'upgrade', 'purchase', 'pickup', 'grant']:
        sound = np.zeros(n)
        notes = [72, 76, 79, 84] if name == 'victory' else [72, 79, 84] if name == 'upgrade' else [79, 84]
        for index, note in enumerate(notes):
            start = min(int(index * length / (len(notes) + 2) * RATE), n - 4)
            part = voice(note, (n - start) / RATE, 'bell')
            sound[start:] += part[:n - start] * .35
    elif name in ['defeat', 'enemy_death']:
        sound = np.sin(2 * np.pi * (100 * t + 55 * .2 * (1 - np.exp(-t / .2)))) * np.exp(-t * 4)
        sound += np.convolve(noise, np.ones(11) / 11, mode='same') * np.exp(-t * 9) * .4
    else:
        # Wood, parchment and short coin sounds for menus.
        sound = (np.sin(2 * np.pi * 310 * t) * .3 + noise * .25) * np.exp(-t * 45)
        if name in ['coin', 'sale']:
            sound += (np.sin(2 * np.pi * 1700 * t) + np.sin(2 * np.pi * 2467 * t) * .3) * np.exp(-t * 23) * .2
    return sound * envelope(n, .004, .045)


def write_wave(path, signal, loop=False, peak=.76):
    signal = np.asarray(signal)
    signal = signal - signal.mean(axis=0)
    maximum = np.max(np.abs(signal))
    if maximum:
        signal *= peak / maximum
    if not loop:
        signal *= envelope(len(signal), .004, .045)[:, None] if signal.ndim == 2 else envelope(len(signal), .004, .045)
    pcm = np.round(np.clip(signal, -.95, .95) * 32767).astype('<i2')
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as target:
        target.setnchannels(2 if signal.ndim == 2 else 1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(pcm.tobytes())
    return {'path': str(path.name), 'seconds': round(len(signal) / RATE, 4), 'loop': loop, 'channels': 2 if signal.ndim == 2 else 1}


def generate(project, profile):
    output = project / 'assets/audio'
    preserve_music = (output / 'music-provenance.json').exists()
    previous = json.loads((output / 'catalog.json').read_text(encoding='utf-8')) if preserve_music else {}
    catalog = {'sample_rate': RATE, 'license': previous.get('license', 'CC0-1.0; original algorithmic compositions and synthesized effects'), 'music': previous.get('music', {}), 'sfx': {}}
    moods = ['welcome', 'study', 'career', 'tycoon'] if profile == 'forbes' else ['exploration', 'settlement', 'combat', 'war']
    for mood in moods:
        if preserve_music:
            assert (output / catalog['music'][mood]['path']).exists(), "Supplied music is missing"
            continue
        track = compose(profile, mood)
        catalog['music'][mood] = write_wave(output / (mood + '.wav'), track, loop=True, peak=.72)
    effects = ['ui_click', 'purchase', 'sale', 'coin', 'upgrade', 'victory', 'defeat']
    effects += ['grant'] if profile == 'forbes' else ['inventory_open', 'pickup', 'potion']
    if profile == 'oaths':
        effects += ['swing', 'attack', 'hit', 'hit_metal', 'hit_flesh', 'block', 'enemy_hurt', 'enemy_death', 'ambience_forest', 'ambience_camp']
        effects += [f'footstep_{material}_{index}' for material in ['grass', 'dirt', 'stone', 'wood', 'snow'] for index in range(3)]
    for name in effects:
        catalog['sfx'][name] = write_wave(output / (name + '.wav'), effect(name), loop=name.startswith('ambience_'), peak=.6 if name.startswith('ambience_') else .78)
    (output / 'catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if not preserve_music:
        (output / 'LICENSE.md').write_text('# Original game audio\n\nThe compositions and synthesized sound effects in this directory were generated specifically for this project using tools/generate_audio.py. No third-party samples were used. The generated audio is dedicated to the public domain under CC0 1.0.\n\nGenerator dependency: NumPy (BSD-3-Clause). NumPy is used only to generate WAV files; it is not distributed with or needed by the game.\n', encoding='utf-8')
    print(f'{profile}: {len(moods)} music loops and {len(effects)} sound effects generated')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--profile', choices=['forbes', 'oaths'], required=True)
    options = parser.parse_args()
    generate(options.project.resolve(), options.profile)
