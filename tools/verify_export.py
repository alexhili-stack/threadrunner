"""Launch the shipped executable with external input fixtures and isolated saves."""
from pathlib import Path
import json
import subprocess
import sys
import time
import zipfile
from package_windows import package

ROOT=Path(__file__).resolve().parents[1]
art=ROOT/'artifacts'
directory=art/f'export-save-{time.time_ns()}'
bundle=art/'export-inputs.json'
routes=[{'index':i,'inputs':json.loads((ROOT/f'tests/fixtures/chapter_{i//10+1:02}_room_{i%10+1:02}.json').read_text())} for i in [0,3,7,12,29,39,40,41,42,43,44]]
bundle.write_text(json.dumps({'routes':routes}))
results=[]
for suffix in ['first','relaunch']:
    if suffix=='relaunch': bundle.write_text(json.dumps({'routes':[],'expect_completed':True}))
    output=art/f'export-{suffix}.json'
    args=[str(ROOT/'builds/windows/Threadrunner.exe'),'--headless','--log-file',str(art/f'export-{suffix}-engine.log'),'--','--save-dir='+str(directory),'--qa-fixture='+str(bundle),'--qa-output='+str(output)]
    done=subprocess.run(args,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
    log=done.stdout.decode('utf-8',errors='replace')
    (art/f'export-{suffix}.log').write_text(log,encoding='utf-8')
    report=json.loads(output.read_text()) if output.exists() else {'pass':False,'error':'No report'}
    report['exit']=done.returncode
    results.append(report)
    print(suffix,done.returncode,report.get('pass'),flush=True)
passed=all(x.get('pass') and x['exit']==0 and not x.get('debug_build',True) for x in results)
(art/'export-verification.json').write_text(json.dumps({'pass':passed,'runs':results},indent=2))
if passed:
    path=ROOT/'builds/windows/manifest.json'
    manifest=json.loads(path.read_text())
    manifest['runtime_verified']=True
    manifest['runtime_verification']='Two standalone processes: eleven real-controller fragment clears, including all five thread lessons, completion UI, restart, save and fresh-process reload; artifacts/export-verification.json'
    path.write_text(json.dumps(manifest,indent=2))
    package(ROOT)
raise SystemExit(0 if passed else 1)
