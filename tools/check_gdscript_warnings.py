"""Compile every shipping GDScript with every Godot4.7 warning promoted to an error.
Run serially while no editor or other importer is writing project.godot. The original
project bytes are restored in finally. QA test scripts are external drivers and are
validated by run_tests.py; the strict inventory covers every file under scripts/.
"""
import argparse, hashlib, json, os, re, subprocess, tempfile
from pathlib import Path
WARNINGS=['UNASSIGNED_VARIABLE', 'UNASSIGNED_VARIABLE_OP_ASSIGN', 'UNUSED_VARIABLE', 'UNUSED_LOCAL_CONSTANT', 'UNUSED_PRIVATE_CLASS_VARIABLE', 'UNUSED_PARAMETER', 'UNUSED_SIGNAL', 'SHADOWED_VARIABLE', 'SHADOWED_VARIABLE_BASE_CLASS', 'SHADOWED_GLOBAL_IDENTIFIER', 'UNREACHABLE_CODE', 'UNREACHABLE_PATTERN', 'STANDALONE_EXPRESSION', 'STANDALONE_TERNARY', 'INCOMPATIBLE_TERNARY', 'UNTYPED_DECLARATION', 'INFERRED_DECLARATION', 'UNSAFE_PROPERTY_ACCESS', 'UNSAFE_METHOD_ACCESS', 'UNSAFE_CAST', 'UNSAFE_CALL_ARGUMENT', 'UNSAFE_VOID_RETURN', 'RETURN_VALUE_DISCARDED', 'STATIC_CALLED_ON_INSTANCE', 'MISSING_TOOL', 'REDUNDANT_STATIC_UNLOAD', 'REDUNDANT_AWAIT', 'MISSING_AWAIT', 'ASSERT_ALWAYS_TRUE', 'ASSERT_ALWAYS_FALSE', 'INTEGER_DIVISION', 'NARROWING_CONVERSION', 'INT_AS_ENUM_WITHOUT_CAST', 'INT_AS_ENUM_WITHOUT_MATCH', 'ENUM_VARIABLE_WITHOUT_DEFAULT', 'EMPTY_FILE', 'DEPRECATED_KEYWORD', 'CONFUSABLE_IDENTIFIER', 'CONFUSABLE_LOCAL_DECLARATION', 'CONFUSABLE_LOCAL_USAGE', 'CONFUSABLE_CAPTURE_REASSIGNMENT', 'CONFUSABLE_TEMPORARY_MODIFICATION', 'INFERENCE_ON_VARIANT', 'NATIVE_METHOD_OVERRIDE', 'GET_NODE_DEFAULT_WITHOUT_ONREADY', 'ONREADY_WITH_EXPORT', 'PROPERTY_USED_AS_FUNCTION', 'CONSTANT_USED_AS_FUNCTION', 'FUNCTION_USED_AS_PROPERTY']
PROBE='extends SceneTree\nfunc _initialize()->void:call_deferred("run")\nfunc run()->void:\n    await process_frame\n    var paths:Array[String]=[]\n    collect("res://scripts",paths)\n    for path:String in paths:\n        var script:Script=load(path)\n        if script==null or not script.can_instantiate():print("COMPILE FAILED: ",path)\n    print("STRICT SCRIPT INVENTORY: ",paths.size())\n    quit()\nfunc collect(folder:String,paths:Array[String])->void:\n    for file:String in DirAccess.get_files_at(folder):\n        if file.ends_with(".gd"):paths.append(folder+"/"+file)\n    for folder_name:String in DirAccess.get_directories_at(folder):collect(folder+"/"+folder_name,paths)\n'
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',required=True)
    parser.add_argument('--artifacts',type=Path,required=True)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    project=root/'project.godot';original=project.read_bytes()
    artifacts=args.artifacts.resolve();artifacts.mkdir(parents=True,exist_ok=True)
    lock=root/'.strict-compile.lock'
    with lock.open('x',encoding='utf-8') as file:file.write(str(os.getpid()))
    try:
        text=original.decode('utf-8')
        text=re.sub(r'^gdscript/warnings/.*\n?','',text,flags=re.M)
        options='gdscript/warnings/enable=true\ngdscript/warnings/directory_rules={}\n'+''.join('gdscript/warnings/'+name.lower()+'=2\n' for name in WARNINGS)
        if '[debug]' in text:text=text.replace('[debug]','[debug]\n'+options,1)
        else:text+='\n[debug]\n'+options
        with tempfile.TemporaryDirectory(prefix='godot-strict-') as temporary:
            temporary=Path(temporary);probe=temporary/'strict_inventory.gd';probe.write_text(PROBE,encoding='utf-8')
            env=os.environ.copy();env['GAME_AUDIO_MUTED']='1'
            for key,folder in [('APPDATA','roaming'),('LOCALAPPDATA','local')]:
                target=temporary/folder;target.mkdir();env[key]=str(target)
            project.write_text(text,encoding='utf-8')
            result=subprocess.run([args.godot,'--headless','--path',str(root),'--script',str(probe)],env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=240)
            output=result.stdout+result.stderr;(artifacts/'strict-compiler.log').write_text(output,encoding='utf-8')
            errors=[line for line in output.splitlines() if any(marker in line for marker in ['SCRIPT ERROR','ERROR:','COMPILE FAILED']) and 'root certificate store' not in line]
            count=re.search(r'STRICT SCRIPT INVENTORY: (\d+)',output)
            passed=result.returncode==0 and not errors and count is not None
            report={'result':'PASS' if passed else 'FAIL','warning_categories':len(WARNINGS),'shipping_scripts':int(count[1]) if count else 0,'errors':errors,'exit_code':result.returncode,'scope':'All shipping scripts/**/*.gd; QA drivers run separately','original_project_sha256':hashlib.sha256(original).hexdigest()}
    finally:
        project.write_bytes(original);lock.unlink()
    report['project_bytes_restored']=project.read_bytes()==original
    (artifacts/'strict-result.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('STRICT SHIPPING COMPILE',report['result'],report['shipping_scripts'],'scripts',len(WARNINGS),'categories')
    if errors:print('\n'.join(errors[:15]))
    return 0 if passed and report['project_bytes_restored'] else 1
if __name__=='__main__':raise SystemExit(main())
