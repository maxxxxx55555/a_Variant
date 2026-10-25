import configparser
from pathlib import Path
root=Path(__file__).resolve().parents[1]
text=(root/'export_presets.cfg').read_text(encoding='utf-8')
filters=[line.split('=',1)[1].strip('"') for line in text.splitlines() if line.startswith('include_filter=')]
for include in filters:
    assert 'data/strings/*.json' in include, 'Compiled locale copy must be explicitly shipped in every preset'
    assert 'third_party/Godot/*.txt' in include, 'Engine notices must ship in every preset'
    assert 'assets/**/*.txt' in include, 'Font and art license bytes must ship in every preset'
print('EXPORT CONTRACT PASS:',len(filters),'presets with compiled data and notices')
