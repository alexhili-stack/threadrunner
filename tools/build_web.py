"""Export the shared Godot game and package its static, GitHub Pages-ready player."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', type=Path)
    args = parser.parse_args()
    engine = args.godot or next((ROOT / '.tools/godot').glob('*console.exe'), None)
    if engine is None:
        raise SystemExit('Provide --godot or install the project-local engine')
    target = ROOT / 'builds/web'
    game = target / 'game'
    game.mkdir(parents=True, exist_ok=True)
    (ROOT / 'artifacts').mkdir(exist_ok=True)
    command = [str(engine.resolve()), '--headless', '--path', str(ROOT), '--log-file',
               str(ROOT / 'artifacts/web-export-engine.log'), '--export-release', 'Web', str(game / 'index.html')]
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (ROOT / 'artifacts/web-export.log').write_bytes(result.stdout)
    if result.returncode:
        print(result.stdout.decode(errors='replace')[-6000:])
        raise SystemExit(result.returncode)
    for source, destination in [('index.html', 'index.html'), ('site.css', 'site.css'), ('site.js', 'site.js'), ('game_host.js', 'game/host.js')]:
        shutil.copy2(ROOT / 'web' / source, target / destination)
    shutil.copytree(ROOT / 'assets/fonts', target / 'fonts', ignore=shutil.ignore_patterns('*.import'), dirs_exist_ok=True)
    shutil.copy2(ROOT / 'assets/art/icon.svg', target / 'icon.svg')
    shutil.copytree(ROOT / 'third_party', target / 'third_party', dirs_exist_ok=True)
    notices = '<!doctype html><html lang="en"><meta charset="utf-8"><title>Threadrunner credits</title><style>body{background:#09171e;color:#f2f3e9;font:16px/1.6 sans-serif;max-width:800px;margin:40px auto;padding:20px}a{color:#58e1c3}</style><h1>Threadrunner — credits and licenses</h1><p>Original game design, vector art and synthesized sound: Alexander Hili with Codex.</p><ul>'
    for file in sorted((target / 'third_party').rglob('*')):
        if file.is_file():
            notices += f'<li><a href="{file.relative_to(target / "third_party").as_posix()}">{file.relative_to(target / "third_party").as_posix()}</a></li>'
    notices += '</ul><p><a href="../">Return to the game</a></p></html>'
    (target / 'third_party/index.html').write_text(notices, encoding='utf-8')
    (target / '.nojekyll').write_text('')
    revision = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True)
    manifest = {'game': 'Threadrunner', 'version': '1.3.0-web', 'engine': '4.7.2', 'threaded': False,
                'source_revision': revision.stdout.strip() if revision.returncode == 0 else None, 'files': {}}
    for file in sorted(target.rglob('*')):
        if file.is_file() and file.name != 'manifest.json':
            manifest['files'][file.relative_to(target).as_posix()] = {'bytes': file.stat().st_size, 'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
    (target / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    assert not any('tests/' in name or 'fixtures' in name or name.endswith('.exe') for name in manifest['files'])
    print(json.dumps({'pass': True, 'files': len(manifest['files']), 'bytes': sum(f['bytes'] for f in manifest['files'].values()), 'threaded': False}), flush=True)


if __name__ == '__main__':
    main()
