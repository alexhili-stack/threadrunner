"""Install exact project-local development dependencies from official sources."""
from pathlib import Path
import hashlib
import io
import json
import shutil
import subprocess
import sys
import urllib.request
import venv
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.tools'
TOOLS.mkdir(exist_ok=True)
HEADERS = {'User-Agent': 'Threadrunner-local-setup'}

def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120) as response:
        return response.read()

def main():
    engine_url = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
    engine_digest = '731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953'
    if not list(TOOLS.glob('godot/*console.exe')):
        blob = fetch(engine_url)
        assert hashlib.sha256(blob).hexdigest() == engine_digest, 'Engine digest mismatch'
        with zipfile.ZipFile(io.BytesIO(blob)) as archive:
            archive.extractall(TOOLS / 'godot')
    source = 'https://api.github.com/repos/godot-gdunit-labs/gdUnit4/zipball/v6.2.2'
    blob = fetch(source)
    digest = hashlib.sha256(blob).hexdigest()
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        prefix = archive.namelist()[0].split('/')[0] + '/'
        for info in archive.infolist():
            rel = info.filename.removeprefix(prefix)
            if rel.startswith('addons/gdUnit4/') and not info.is_dir():
                target = ROOT / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(info))
        for name in ['LICENSE', 'README.md']:
            found = next((x for x in archive.namelist() if x == prefix + name), None)
            if found:
                target = ROOT / 'third_party' / 'gdunit4' / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(found))
    # Review metadata/source before executing the add-on during engine import.
    print('GdUnit4 source installed; addon execution deferred to import.', flush=True)
    venv.create(ROOT / '.venv', with_pip=True)
    python = ROOT / '.venv/Scripts/python.exe'
    subprocess.run([str(python), '-m', 'pip', 'install', 'gdtoolkit==4.5.0'], check=True)
    lock = {
        'godot': {'version': '4.7.2-stable', 'source': engine_url, 'sha256': engine_digest, 'license': 'MIT'},
        'gdunit4': {'version': '6.2.2', 'source': source, 'archive_sha256': digest, 'license': 'MIT', 'location': 'addons/gdUnit4'},
        'gdtoolkit': {'version': '4.5.0', 'source': 'https://pypi.org/project/gdtoolkit/4.5.0/', 'license': 'MIT', 'location': '.venv'},
        'godot_mcp': {'enabled': False, 'reason': 'CLI provides the required launch/import/test feedback'},
        'godotsteam': {'enabled': False, 'reason': 'Standalone build; no Steam feature requested'}
    }
    (ROOT / 'tools/dependencies.lock.json').write_text(json.dumps(lock, indent=2) + '\n')
    with (ROOT / 'tools/requirements-resolved.txt').open('w') as output:
        subprocess.run([str(python), '-m', 'pip', 'freeze'], stdout=output, check=True)
    print('Local dependencies installed.', flush=True)

if __name__ == '__main__':
    main()
