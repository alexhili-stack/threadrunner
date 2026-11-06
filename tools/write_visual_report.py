"""Consolidate executed v1.2 evidence; refuse incomplete or failing results."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artifacts'


def read(name):
    return json.loads((ART / name).read_text(encoding='utf-8'))


qa = read('qa_summary.json')
assert qa['pass'] and not qa['accelerated'], 'Full real-time QA must pass'
unit = next(item for item in qa['results'] if item['name'] == 'test-discovery')
assert unit['tests'] >= 46 and unit['failures'] == unit['errors'] == 0
levels = read('levels.json')
assert levels['pass'] and levels['rooms'] == 45
fixtures = read('fixture_integrity.json')
assert fixtures['pass'] and fixtures['files'] == 85
routes = read('routes_replay.json')
normal = read('routes_replay-normal.json')
bypass = read('routes_bypass.json')
assert len(routes) == len(normal) == len(bypass) == 40
assert all(item['pass'] for item in routes + normal + bypass)
threads = read('thread_routes.json')
assert threads['pass'] and len(threads['rooms']) == 5
assert all(item['repetitions'] == 3 and item['no_tool_rejected'] for item in threads['rooms'])
ui = read('ui.json')
assert len(ui) >= 33 and all(item['pass'] for item in ui)
reset = read('reset_metrics.json')
assert reset['samples'] == 500 and reset['worst_ms'] <= 250 and reset['orphans'] == 0
soak = read('soak.json')
assert soak['duration_seconds'] >= 900 and not soak['failures']
release = read('export-verification.json')
assert release['pass'] and len(release['runs']) == 2
assert all(item['pass'] and not item['debug_build'] and item['exit'] == 0 for item in release['runs'])
graphical_release = read('release-graphical.json')
assert graphical_release['pass'] and graphical_release['graphical_backend']
profile = read('profile.json')
manifest_path = ROOT / 'builds/windows/manifest.json'
manifest = json.loads(manifest_path.read_text())
assert manifest['build_id'] == 'threadrunner-1.2.0-local' and manifest['runtime_verified']
source_hash = hashlib.sha256()
for folder in ['scripts', 'scenes', 'data', 'assets']:
    for path in sorted((ROOT / folder).rglob('*')):
        if path.is_file() and path.suffix != '.import':
            source_hash.update(path.relative_to(ROOT).as_posix().encode())
            source_hash.update(path.read_bytes())
source_hash.update((ROOT / 'project.godot').read_bytes())
assert source_hash.hexdigest() == manifest['source_sha256'], 'Source changed after export'
for name, info in manifest['files'].items():
    path = ROOT / 'builds/windows' / name
    assert path.stat().st_size == info['bytes']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == info['sha256']
with zipfile.ZipFile(ROOT / 'builds/Threadrunner-Windows.zip') as archive:
    assert archive.testzip() is None
    assert not any(name.endswith('.TMP') or '/artifacts/' in name or '/tests/' in name for name in archive.namelist())
    for name in manifest['files']:
        assert hashlib.sha256(archive.read('Threadrunner/' + name)).hexdigest() == manifest['files'][name]['sha256']
    for name in ['Barlow-OFL.txt', 'Manrope-OFL.txt']:
        assert 'Threadrunner/third_party/fonts/' + name in archive.namelist()

evidence = ROOT / 'docs/evidence/v1.2'
evidence.mkdir(parents=True, exist_ok=True)
names = ['qa_summary.json', 'levels.json', 'fixture_integrity.json', 'routes_replay.json',
         'routes_replay-normal.json', 'routes_bypass.json', 'thread_routes.json', 'ui.json',
         'reset_metrics.json', 'soak.json', 'profile.json', 'export-verification.json', 'release-graphical.json']
for name in names:
    shutil.copy2(ART / name, evidence / name)
shutil.copy2(manifest_path, evidence / 'build-manifest.json')
unit_xml = max((ART / 'qa-unit').rglob('results.xml'), key=lambda p:p.stat().st_mtime)
shutil.copy2(unit_xml, evidence / 'unit-results.xml')
for path in ART.glob('qa-before-ui-recheck-*.json'):
    shutil.copy2(path, evidence / path.name)

review_names = ['menu_1280','menu_640','gameplay_1280','select_1280','settings_1280',
                'controls_640','display_640','thread_controls_1280','completion_640',
                'credits_640','thread_select_640','afterlight_scrolling_640',
                'thread_41_action','thread_42_action','thread_43_action','thread_44_action','thread_45_action']
review_dir = ROOT / '.impeccable/review'
review_dir.mkdir(parents=True, exist_ok=True)
for name in review_names:
    shutil.copy2(ART / 'captures' / (name + '.png'), review_dir / (name + '.png'))

clear_count = sum(item['repetitions'] for item in routes + normal + threads['rooms'])
release_count = sum(len(item['checks']) for item in release['runs'])
report = f'''# Threadrunner 1.2 — local acceptance

Verified local Windows x64 build: **{manifest['build_id']}**. The game now has a rebuilt native interface and all three requested thread tools, across forty campaign rooms and five new Threadwork lessons.

## Implemented

- Original thread identity across title, courier/scarf, HUD, menus, exits and effects. Licensed Barlow Condensed and Manrope replace the default font; platform edges, hazard silhouettes and chapter backgrounds are clearer.
- Chapter tabs, aspect-preserving room previews, separated settings pages, visible keyboard/controller focus, remapping and adaptive prompts. The rewind meter is an actual 140 × 2 logical-pixel rail.
- E / X stitches paired bridges and powers relays; F / B grapples and releases; holding Shift / LB retraces up to six seconds of the actual trail. Jump releases a grapple upward. Time and traps continue during rewind, and solid geometry can stop it.
- Five lessons teach bridge, swing, relay, rewind and a combined scrolling course. Choose **Thread lessons** from the main menu. The forty existing rooms retain their geometry and tested routes, with authored thread terminals and sockets added.
- Stable IDs, progress, fragments and settings are preserved. Layout revision 3 archives earlier times so different tool conditions do not compete in current PBs. Legacy remaps retain their keys when new defaults conflict.

## Executed evidence

| Check | Actual outcome |
|---|---|
| Formatter, linter, editor import | PASS |
| GdUnit4 discovery and assertions | {unit['tests']} cases, 0 failures, 0 errors |
| Failure and empty-suite probes | Expected failure exits 100; empty coverage rejected |
| Level validator | 45 scenes, no issues |
| Input consistency | 85 files, {fixtures['frames']:,} frames, no issues |
| Real-controller campaign routes | 40 fragment and 40 ordinary routes × 3, all clear |
| Real-controller thread lessons | 5 routes × 3, all clear with fragments and zero deaths |
| Total successful route replays | {clear_count} |
| Negative attempts | 40 hold-right/no-jump bypasses and five no-tool lesson walks rejected |
| Graphical input/UI checks | {len(ui)}/{len(ui)} PASS |
| Retry stress | 500 resets; median {reset['median_ms']:.3f} ms, worst {reset['worst_ms']:.3f} ms; no node increase, {reset['orphans']} orphans |
| Real-time headless soak | {soak['duration_seconds']:.2f} seconds, {soak['cycles']} room cycles, 0 recorded failures |
| Standalone Windows processes | Eleven fragment clears, completion pages, restarts, save/relaunch and test-addon exclusion; {release_count}/{release_count} checks PASS |
| Packaged graphical backend | OpenGL initialized, menu/save/test-addon smoke {len(graphical_release['checks'])}/{len(graphical_release['checks'])} PASS, clean exit 0; muted isolated test window |
| Portable ZIP | CRC, EXE/PCK hashes and both font notices verified |

The initial graphical run correctly paused when the research browser took foreground focus. Its completion-page assertion failed. An isolated diagnostic rerun reproduced a successful clear, and a canonical targeted UI recheck passed all assertions. The prior result is retained in qa_summary.json's recheck history and the evidence directory; no assertion was removed or weakened.

The full soak began before the final presentation-only HUD rail, prompt placement and state-color corrections. Movement, tool physics, collision geometry, hazard timing and route fixtures were unchanged. Final presentation and remapping-aware lesson copy were checked graphically; the final exported PCK was separately exercised through its standalone processes.

## Render and timing review

Actual Godot graphical captures at 640 × 360 and 1280 × 720 were inspected for menu, selection, settings, pause, completion, credits, campaign rooms and active tool states. The independent finishing reviewer validated 17 captures, requested one compact-HUD correction, then scored that fix resolved with no visible batch regressions. Its final **ship** disposition covers that scored fix, not an unperformed human playtest. Durable tokens are in DESIGN.md and .impeccable/design.json.

Frame intervals were sampled for ten seconds each on Windows, {profile['cpu']}, {profile['gpu']}, 1280 × 720, GL Compatibility, 120 FPS cap, while the headless soak ran concurrently. These are process-frame intervals; GPU presentation was not measured.

| Room | Median frame interval | 95th percentile | Worst interval |
|---|---:|---:|---:|
'''
for row in profile['rooms']:
    report += f"| {row['room']} | {row['median_frame_ms']:.3f} ms | {row['p95_frame_ms']:.3f} ms | {row['worst_frame_ms']:.3f} ms |\n"
report += f'''
## Not run / limits

Human difficulty/fun and keyboard/controller feel, subjective listening, a physical controller and hardware unplug, other operating systems, and store/public-release checks were NOT RUN. Synthetic controller events and explicit disconnect/focus-loss handlers were tested; they are not physical-hardware evidence. No publishing, account action or system-wide installation occurred.

The native Windows capture API timed out on the packaged OpenGL window and the window was absent on its retry. Therefore no packaged-window screenshot is claimed. A fresh isolated graphical-backend process subsequently initialized OpenGL and passed five smoke checks with clean exit 0. The inspected full screenshots come from the actual graphical Godot source runtime, not a mockup.

## Build and evidence

- Play: builds/windows/Threadrunner.exe beside Threadrunner.pck, or Play Threadrunner.cmd.
- Portable package: builds/Threadrunner-Windows.zip; a versioned 1.2 copy is preserved alongside 1.0 and 1.1.
- Manifest source SHA-256: `{manifest['source_sha256']}`. Live source and package files match it.
- Machine-readable evidence and unit XML: docs/evidence/v1.2. Full process logs remain in artifacts.
- Research: docs/visual_research.md. Mechanic details: docs/thread_tool.md. Rights: docs/asset_provenance.md and third_party/fonts.
'''
(ROOT / 'docs/visual_acceptance_report.md').write_text(report, encoding='utf-8')
(ROOT / 'docs/qa_report.md').write_text(report, encoding='utf-8')
shutil.copy2(ROOT / 'builds/Threadrunner-Windows.zip', ROOT / 'builds/Threadrunner-1.2.0-Windows.zip')
print(json.dumps({'pass':True,'tests':unit['tests'],'route_clears':clear_count,'ui_checks':len(ui),'release_checks':release_count,'soak_seconds':soak['duration_seconds'],'source_matches_export':True}))
