"""Compile editable CSV translations into export-safe runtime data."""
import csv
import json
from pathlib import Path
import re


def compile_catalog(root):
    result = {}
    for language in ('ru', 'en'):
        path = root / 'data/strings' / (language + '.csv')
        with path.open(encoding='utf-8-sig', newline='') as source:
            for row in csv.DictReader(source):
                assert None not in row, f'Malformed CSV: {row}'
                key = row['key']
                assert row[language].strip(), f'Empty {language} translation: {key}'
                result.setdefault(key, {})[language] = row[language].strip()
    for key, value in result.items():
        assert set(value) == {'ru', 'en'}, f'Missing language for {key}'
        assert set(re.findall(r'\{\w+\}', value['ru'])) == set(re.findall(r'\{\w+\}', value['en'])), f'Parameter mismatch: {key}'
    destination = root / 'data/balance/localization.json'
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Compiled {len(result)} RU/EN translations')


if __name__ == '__main__':
    compile_catalog(Path(__file__).resolve().parents[1])
