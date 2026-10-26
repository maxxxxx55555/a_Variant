"""Public pack must exclude QA routes; an export feature alone is insufficient."""
import configparser,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
config=configparser.ConfigParser(interpolation=None,strict=False)
config.read(root/'export_presets.cfg',encoding='utf-8')
def value(section,key):return config[section].get(key,'').strip('"')
presets=[s for s in config.sections() if re.fullmatch(r'preset\.\d+',s)]
qa=[s for s in presets if value(s,'name')=='Windows QA']
public=[s for s in presets if value(s,'name')=='Windows Desktop']
assert len(qa)==1 and len(public)==1,'Separate public and private QA presets are required'
route='scripts/verification/*'
for section in public:
    assert 'qa_verifier' not in value(section,'custom_features')
    assert route in value(section,'exclude_filter'),'Public exporter must physically omit the verifier'
for section in qa:
    assert 'qa_verifier' in value(section,'custom_features')
    assert route not in value(section,'exclude_filter')
for section in public+qa:
    assert value(section,'encrypt_pck')=='true' and value(section,'encrypt_directory')=='true'
    assert value(section,'encryption_include_filters')=='*'
    assert value(section,'script_export_mode')=='2'
    assert value(section+'.options','debug/export_console_wrapper')=='0'
for source in (root/'scripts').rglob('*.gd'):
    if 'verification' in source.parts or source.name=='ReleaseVerification.gd':continue
    assert not re.search(r'preload\([^\n]*CampaignRoute',source.read_text()),source
router=(root/'scripts/security/QARouter.gd').read_text()
assert 'OS.has_feature("qa_verifier")' in router and 'OS.get_environment("GAME_QA")' in router
print('PUBLIC QA CONTRACT PASS: separate feature/env gate, physical exclusion, encrypted presets')
