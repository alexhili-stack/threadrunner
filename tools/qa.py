"""Canonical local QA wrapper. Every required failure produces a nonzero exit."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artifacts'
ART.mkdir(exist_ok=True)
ENV=os.environ.copy()
ENV['LOCALAPPDATA']=str(ROOT/'.tools/cache')
PY=ROOT/'.venv/Scripts/python.exe'
results=[]

def run(label, command, timeout=180, expected=0, allow_cert=True):
    start=time.monotonic()
    if label=='ui' and (ART/'ui.json').exists():
        shutil.copy2(ART/'ui.json',ART/f'ui-before-check-{time.time_ns()}.json')
        (ART/'ui.json').unlink()
    try:
        done=subprocess.run([str(x) for x in command],cwd=ROOT,env=ENV,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        output=done.stdout.decode('utf-8',errors='replace')
        (ART/f'{label}.log').write_text(output,encoding='utf-8')
        errors=[line for line in output.splitlines() if re.search(r'(^|\s)(SCRIPT ERROR:|ERROR:)',line)]
        if allow_cert:
            errors=[line for line in errors if 'Failed to read the root certificate store' not in line]
        if label=='ui':
            checks=json.loads((ART/'ui.json').read_text()) if (ART/'ui.json').exists() else []
            if len(checks)<38 or any(not item.get('pass',False) for item in checks):
                errors.append(f'Incomplete or failing graphical report: {len(checks)}/38 checks')
        passed=done.returncode==expected and (not errors or expected!=0)
        result={'name':label,'pass':passed,'exit':done.returncode,'expected':expected,'seconds':round(time.monotonic()-start,3),'errors':errors}
    except (subprocess.TimeoutExpired,OSError) as exc:
        result={'name':label,'pass':False,'error':str(exc),'seconds':round(time.monotonic()-start,3)}
    results.append(result)
    print(json.dumps(result),flush=True)
    return result

def xml_counts(directory):
    reports=list(directory.rglob('results.xml'))
    if not reports: return {'tests':0,'failures':0,'errors':0}
    report=max(reports,key=lambda x:x.stat().st_mtime)
    tree=ET.parse(report)
    cases=tree.findall('.//testcase')
    return {'tests':len(cases),'failures':len(tree.findall('.//failure')),'errors':len(tree.findall('.//error'))}

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--godot',type=Path)
    p.add_argument('--quick',action='store_true')
    p.add_argument('--soak',action='store_true')
    p.add_argument('--ui',action='store_true')
    p.add_argument('--export',action='store_true')
    p.add_argument('--recheck-ui',action='store_true',help='Rerun graphical checks and retain the previous result in the audit history')
    p.add_argument('--recheck-static',action='store_true',help='Rerun formatting and lint, retaining earlier results in the audit history')
    a=p.parse_args()
    engine=a.godot or next((ROOT/'.tools/godot').glob('*console.exe'),None)
    if engine is None:
        print('BLOCKED: provide --godot or run tools/install_tools.py');return 2
    if a.recheck_static:
        report_path=ART/'qa_summary.json'
        if not report_path.exists():
            print('BLOCKED: a complete QA report is required before a targeted recheck');return 2
        report=json.loads(report_path.read_text())
        shutil.copy2(report_path,ART/f'qa-before-static-recheck-{time.time_ns()}.json')
        for label, module in [('format','gdtoolkit.formatter'),('lint','gdtoolkit.linter')]:
            previous=next((item for item in report['results'] if item['name']==label),None)
            if previous is None:
                print('BLOCKED: previous report has no static checks');return 2
            log=ART/f'{label}.log'
            if log.exists(): shutil.copy2(log,ART/f'{label}-before-recheck-{time.time_ns()}.log')
            command=[PY,'-m',module,*(['--check'] if label=='format' else []),'scripts','tests','tools']
            current=run(label,command)
            report.setdefault('rechecks',[]).append({'previous':previous,'current':current,'utc':datetime.now(timezone.utc).isoformat()})
            report['results']=[current if item['name']==label else item for item in report['results']]
        report['pass']=all(item['pass'] for item in report['results'])
        report['utc']=datetime.now(timezone.utc).isoformat()
        report_path.write_text(json.dumps(report,indent=2))
        print('QA PASSED' if report['pass'] else 'QA FAILED',flush=True)
        return 0 if report['pass'] else 1
    if a.recheck_ui:
        report_path=ART/'qa_summary.json'
        if not report_path.exists():
            print('BLOCKED: a complete QA report is required before a targeted recheck');return 2
        report=json.loads(report_path.read_text())
        previous=next((item for item in report['results'] if item['name']=='ui'),None)
        if previous is None:
            print('BLOCKED: the previous run did not include graphical UI checks');return 2
        shutil.copy2(report_path,ART/f'qa-before-ui-recheck-{time.time_ns()}.json')
        if (ART/'ui.log').exists():
            shutil.copy2(ART/'ui.log',ART/f'ui-before-recheck-{time.time_ns()}.log')
        current=run('ui',[engine,'--path',ROOT,'--log-file',ART/'ui-engine.log','--script','tools/ui_smoke.gd','--',f'--save-dir=res://artifacts/ui-recheck-{time.time_ns()}'],timeout=180)
        report.setdefault('rechecks',[]).append({'previous':previous,'current':current,'utc':datetime.now(timezone.utc).isoformat()})
        report['results']=[current if item['name']=='ui' else item for item in report['results']]
        report['pass']=all(item['pass'] for item in report['results'])
        report['utc']=datetime.now(timezone.utc).isoformat()
        report_path.write_text(json.dumps(report,indent=2))
        print('QA PASSED' if report['pass'] else 'QA FAILED',flush=True)
        return 0 if report['pass'] else 1
    def godot(label,*args):
        return [engine,'--headless','--path',ROOT,'--log-file',ART/f'{label}-engine.log',*args]
    targets=['scripts','tests','tools']
    run('format',[PY,'-m','gdtoolkit.formatter','--check',*targets])
    run('lint',[PY,'-m','gdtoolkit.linter',*targets])
    run('import',godot('import','--editor','--import','--quit'))
    runner=['--script','addons/gdUnit4/bin/GdUnitCmdTool.gd','--ignoreHeadlessMode','-c']
    fixed=['--fixed-fps','60'] if a.quick else []
    run('gdunit',godot('gdunit',*fixed,*runner,'-a','res://tests','-rd','res://artifacts/qa-unit'),timeout=180)
    counts=xml_counts(ART/'qa-unit')
    results.append({'name':'test-discovery','pass':counts['tests']>=49 and counts['failures']==0 and counts['errors']==0,**counts})
    run('failure-probe',godot('probe','--fixed-fps','60',*runner,'-a','res://tests/gameplay/test_setup.gd','-rd','res://artifacts/probe-fail','--','--probe-fail'),expected=100)
    probe=xml_counts(ART/'probe-fail')
    results.append({'name':'failure-propagation','pass':probe['tests']==1 and probe['failures']==1,**probe})
    run('zero-probe',godot('zero','--fixed-fps','60',*runner,'-a','res://tests/empty','-rd','res://artifacts/probe-zero'),expected=0)
    zero=xml_counts(ART/'probe-zero')
    results.append({'name':'zero-test-rejection','pass':zero['tests']==0,'wrapper_accepts_empty':False})
    run('fixture-inputs',[PY,'tools/validate_fixtures.py'])
    run('levels',godot('levels','--script','tools/validate_levels.gd'))
    run('routes',godot('routes','--fixed-fps','60','--script','tools/route_runner.gd','--','--mode=replay'))
    run('thread-routes',godot('thread-routes','--fixed-fps','60','--script','tools/thread_routes.gd'))
    run('bypass',godot('bypass','--fixed-fps','60','--script','tools/route_runner.gd','--','--mode=bypass'))
    run('normal-routes',godot('normal-routes','--fixed-fps','60','--script','tools/route_runner.gd','--','--mode=replay-normal'))
    if a.ui:
        run('ui',[engine,'--path',ROOT,'--log-file',ART/'ui-engine.log','--script','tools/ui_smoke.gd','--','--save-dir=res://artifacts/ui-save'],timeout=180)
    if a.soak:
        run('soak',godot('soak','--script','tools/soak.gd','--','--save-dir=res://artifacts/soak-save'),timeout=1200)
    if a.export:
        run('export',[PY,'tools/build.py'],timeout=180)
        run('export-runtime',[PY,'tools/verify_export.py'],timeout=180)
    report={'utc':datetime.now(timezone.utc).isoformat(),'accelerated':a.quick,'engine':str(engine.relative_to(ROOT)) if engine.is_relative_to(ROOT) else engine.name,'results':results,'pass':all(x['pass'] for x in results)}
    (ART/'qa_summary.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('QA PASSED' if report['pass'] else 'QA FAILED',flush=True)
    return 0 if report['pass'] else 1

if __name__=='__main__':
    raise SystemExit(main())
