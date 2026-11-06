from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import zipfile
from package_windows import package

ROOT=Path(__file__).resolve().parents[1]
engine=next((ROOT/'.tools/godot').glob('*console.exe'))
target=ROOT/'builds/windows'
target.mkdir(parents=True,exist_ok=True)
result=subprocess.run([str(engine),'--headless','--path',str(ROOT),'--log-file',str(ROOT/'artifacts/export-engine.log'),'--export-release','Windows Desktop',str(target/'Threadrunner.exe')])
if result.returncode: raise SystemExit(result.returncode)
shutil.copytree(ROOT/'third_party',target/'third_party',dirs_exist_ok=True)
(target/'README.txt').write_text('THREADRUNNER\nRun Threadrunner.exe with Threadrunner.pck beside it.\nA/D or arrows move, Space/Up jumps, R retries, Esc pauses.\nE stitches bridges, F grapples/releases, hold Shift rewinds the laid trail.\nController: stick/D-pad, A jump, X stitch, B grapple, LB rewind, Y retry, Start pause.\n45 rooms including five Threadwork lessons, accessible from the main menu.\nSettings include remapping, audio, fullscreen and reduced effects.\nEnglish. Standalone Windows x64 build.\nSee third_party for notices.\n',encoding='utf-8')
source_hash=hashlib.sha256()
for folder in ['scripts','scenes','data','assets']:
    for path in sorted((ROOT/folder).rglob('*')):
        if path.is_file() and path.suffix not in ['.import']:
            source_hash.update(path.relative_to(ROOT).as_posix().encode())
            source_hash.update(path.read_bytes())
source_hash.update((ROOT/'project.godot').read_bytes())
revision=subprocess.run(['git','rev-parse','--verify','HEAD'],cwd=ROOT,capture_output=True,text=True)
manifest={'build_id':'threadrunner-1.4.0-local','godot':'4.7.2.stable.official.ed1daf0bf','target':'Windows x86_64','source_revision':revision.stdout.strip() if revision.returncode==0 else None,'source_sha256':source_hash.hexdigest(),'files':{},'qa_report':'docs/qa_report.md','runtime_verified':False}
for path in sorted(target.glob('*')):
    if path.is_file() and path.suffix in ['.exe','.pck']:
        manifest['files'][path.name]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
(target/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
package(ROOT)
print(json.dumps(manifest,indent=2))
