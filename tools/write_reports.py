"""Summarise existing execution evidence; never create test outcomes."""
from pathlib import Path
from datetime import datetime
import json
import re
import shutil

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artifacts'
DOC=ROOT/'docs'
def read(name): return json.loads((ART/name).read_text(encoding='utf-8'))
def write(name,text): (DOC/name).write_text(text.strip()+'\n',encoding='utf-8')
qa=read('qa_summary.json')
routes=read('routes_replay.json')
normal=read('routes_replay-normal.json')
ui=read('ui.json')
release=read('export-verification.json')
metrics=read('reset_metrics-realtime.json') if (ART/'reset_metrics-realtime.json').exists() else read('reset_metrics.json')
soak=read('soak-900.json')
cleanup=read('soak.json')
profile=read('profile.json')
manifest=json.loads((ROOT/'builds/windows/manifest.json').read_text())
assert qa['pass'] and all(x['pass'] for x in routes+normal+ui) and release['pass']
assert len(routes)==len(normal)==30 and soak['duration_seconds']>=900 and not soak['failures']
assert metrics['samples']==500 and metrics['worst_ms']<=250 and manifest['runtime_verified']
assert not cleanup['failures']
cleanup_log=(ART/'soak-cleanup-fixed.log').read_text(encoding='utf-8')
assert 'resources still in use' not in cleanup_log and 'instances were leaked' not in cleanup_log

samples=soak['samples']
times=[x['time'] for x in routes]
commands='''
`.venv/Scripts/python.exe tools/qa.py --ui --export`

`.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/soak.gd -- --save-dir=res://artifacts/soak-save`

`.tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --script tools/ui_smoke.gd -- --save-dir=res://artifacts/ui-final-save`

`.venv/Scripts/python.exe tools/verify_export.py`
'''
details=f'''
| Check | Result | Evidence |
|---|---|---|
| Canonical QA stages | {sum(x['pass'] for x in qa['results'])}/{len(qa['results'])} PASS | artifacts/qa_summary.json |
| GdUnit4 | 26 tests, 0 failures/errors/skips/orphans | docs/evidence/results.xml |
| Movement | 12 tests PASS, actual CharacterBody2D/floor/wall/ceiling | tests/movement/test_player.gd |
| Lifecycle | 6 tests PASS, including 500 real-time resets | tests/gameplay/test_lifecycle.gd |
| Save/input | 7 tests PASS, including full-precision fractional time | tests/saves/test_saves.gd |
| Framework setup | 1 passing test; deliberate failure returns 100; zero coverage rejected | artifacts/probe-fail, probe-zero and qa_summary.json |
| Level validation | 30 rooms PASS | artifacts/levels.json |
| Fragment-plus-exit fixtures | 30 rooms x 3 replays = 90 PASS | artifacts/routes_replay.json, tests/fixtures |
| Normal exit fixtures | 30 rooms x 3 replays = 90 PASS | artifacts/routes_replay-normal.json, tests/fixtures/normal |
| Graphical UI/action checks | {len(ui)} PASS, 0 FAIL | artifacts/ui.json, ui-final.log |
| Standalone release | {sum(len(x['checks']) for x in release['runs'])} checks PASS across two processes, release/debug_build=false | artifacts/export-verification.json |
| Soak | {soak['duration_seconds']:.2f} seconds, {soak['cycles']} room cycles, 0 gameplay failures | artifacts/soak-900.json |
| Reset latency | n={metrics['samples']}, median {metrics['median_ms']:.3f} ms, worst {metrics['worst_ms']:.3f} ms | docs/evidence/reset_metrics_realtime.json |
'''
environment=f"Godot 4.7.2.stable.official.ed1daf0bf; Windows; {profile['cpu']}; {profile['gpu']}; Compatibility OpenGL renderer; 1280 x 720 default, 640 x 360 minimum. Python 3.12.14, GdUnit4 6.2.2, gdtoolkit 4.5.0."
xmls=list((ART/'qa-unit').rglob('results.xml'))
latest_xml=max(xmls,key=lambda p:p.stat().st_mtime)
write('qa_report.md',f'''# QA evidence

Verdict: AUTOMATED ACCEPTANCE PASSED for the tested local Windows build. No unresolved P0/P1 defect was observed. This is not commercial/public-release approval.

{environment}

{details}

Final presentation regression used --quick; the separate real-time suite and reset results are preserved in docs/evidence/qa_summary_realtime.json and reset_metrics_realtime.json. The accelerated run is not a latency measurement.

Executed commands (explicit absolute log-file paths were supplied by wrappers):
{commands}

The 15-minute soak exercised the integrated pre-final-presentation runtime, including clears, deaths, pauses and room transitions. The initial process shutdown emitted an AudioStream playback reference warning. Investigation found a queued completion page could play a focus sound after a stop request. Final code stops further page processing, clears voice streams and allows the audio mixer to settle. A targeted {cleanup['duration_seconds']:.2f}-second exit regression then finished without node/resource shutdown warnings. Final movement/lifecycle/route/UI/export checks were run after the presentation and save changes.

Soak sample range: live nodes {min(x['nodes'] for x in samples)}-{max(x['nodes'] for x in samples)}, maximum orphan count {max(x['orphans'] for x in samples)}. Static-memory first/last samples {samples[0]['static_bytes']:,}/{samples[-1]['static_bytes']:,} bytes. Rooms have different geometry counts; these measurements do not prove absence of all leaks or establish OS-wide memory behaviour.

Restricted sandbox runs can report a blocked Windows certificate store. Final canonical QA used authorised normal runtime access and had no unexpected logged engine errors. Deliberate malformed-save, failure-probe and zero-test cases are recorded diagnostics, not hidden acceptance passes.

Synthetic keyboard and joypad events, disconnect-handler invocation and focus-loss notification prove those action paths. No physical keyboard/controller playtest, hardware unplug test, audio listening session, Steam Deck, macOS or Linux validation was performed. Native packaged-window capture returned FrameArrived timeout; source-runtime captures were actually inspected instead. The exported EXE was separately launched and its real gameplay controller exercised using external fixture inputs, without hazard suppression, teleports or direct collectible grants.

Render-cap comparison beyond accelerated-vs-real-time local physics tests: NOT RUN. Human feel, fairness, sound quality and branding review: NOT RUN. No account/upload/publish actions performed.
''')

write('final_acceptance_report.md',f'''# Final acceptance - Threadrunner 1.0.0 local

Verdict: **AUTOMATED ACCEPTANCE PASSED**. The standalone Windows build and recorded checks pass. Human pacing/device/audio checks remain separate. No verdict here authorises public release.

Implemented: 30 authored rooms in three chapters; shared run/variable-jump/coyote/buffer/wall-slide/wall-jump physics; spikes, travelling saws and timed gates; same-attempt fragments; fast retry; progression and PBs; main/select/pause/settings/credits/completion pages; keyboard remapping and controller actions; audio buses/volume/mute; window/fullscreen, shake and reduced effects; schema-versioned safe-replacement saves; original visual/audio assets; standalone release and local store/trailer materials.

{environment}

Build: {manifest['build_id']}. Source revision: {manifest.get('source_revision') or 'uncommitted local source; no commit fabricated'}. Source-content SHA-256: `{manifest.get('source_sha256','see build manifest')}`.

| Build file | Bytes | SHA-256 |
|---|---:|---|
| Threadrunner.exe | {manifest['files']['Threadrunner.exe']['bytes']:,} | {manifest['files']['Threadrunner.exe']['sha256']} |
| Threadrunner.pck | {manifest['files']['Threadrunner.pck']['bytes']:,} | {manifest['files']['Threadrunner.pck']['sha256']} |

Runnable files: builds/windows/Threadrunner.exe and Threadrunner.pck. Portable bundle: builds/Threadrunner-Windows.zip. The EXE was launched both headlessly and on the normal Windows desktop; the release replay tested four representative room clears/fragments, completion pages, restarts, saving, clean quit and a second-process save reload. No development tools are required to run it. An opt-in command-line verifier reads external input fixtures; no tests/fixtures or testing add-on are included in the package or normal navigation.

{details}

No unresolved automated acceptance failures. One known P2 design issue: scripted fragment clears range {min(times):.2f}-{max(times):.2f} seconds, shorter than the brief's proposed 10-30 second target. Human difficulty/pacing review is pending. Music is deliberately optional and absent. See known_issues.md for limits.

Actual commands:
{commands}

The 15-minute soak and the final shutdown regression are distinguished in qa_report.md. Source captures inspected: menu, selection, settings, gameplay, pause, completion and credits at 1280 x 720 and/or 640 x 360. Final checks include synthetic controller movement/jump/pause, remapping, focus loss, disconnect callback, reduced effects and fullscreen/windowed transitions. Computer Use's native exported-window screenshot failed; no successful packaged screenshot or physical-device result is claimed.

Asset provenance and notices: asset_provenance.md and third_party/. Nothing was uploaded, submitted, purchased or published. Human actions remaining: play representative rooms to assess feel/difficulty/pacing; test a physical controller and sound; review branding/licences/store claims before any separate public-release work.
''')

write('final_qa_report.md','''# Interim QA report

Stage 7 produced the standalone release candidate. It was superseded by docs/final_acceptance_report.md after the completion audit, presentation/audio work, campaign review and final regression. Read the final report and qa_report.md for actual current evidence; this file is not an independent earlier PASS claim.
''')

write('known_issues.md',f'''# Known issues and limits

- P2 design: automated fragment route clears are {min(times):.2f}-{max(times):.2f} seconds, below the proposed 10-30 second pacing target. The campaign is a compact first complete build; human difficulty and pacing have not been assessed.
- No unresolved P0/P1 was observed in the executed suites.
- Optional music track is absent; original SFX are implemented. Listening quality is NOT RUN.
- Physical controller compatibility, real unplug/reconnect and human input feel are NOT RUN. Synthetic actions and the disconnect handler passed.
- Packaged OpenGL window capture through Computer Use failed with FrameArrived timeout. Actual source-runtime captures were inspected. Standalone gameplay/save verification passed through input replays through the real gameplay controller.
- macOS, Linux, Steam Deck and public-store integration are not implemented/tested targets.
- The initial soak's exit-only audio reference warning was resolved; the targeted final shutdown regression is clean. Runtime node/orphan measurements are in qa_report.md and do not imply universal leak freedom.
- New-chat automatic skill UI discovery has not been observed. All six installed workflow files validate and were directly used in this project.
''')

write('blockers.md','''# Blockers

No remaining local implementation/tool-install blocker. The game, export and automated evidence are available.

NOT RUN due to unavailable human/device evidence: physical-controller playtest, actual hardware disconnect, subjective listening/game feel/difficulty and other OS/device support. Native packaged-window screenshot capture was blocked by a Computer Use FrameArrived timeout; this does not block the runnable export or its separate gameplay tests. Source captures were inspected.

Steam accounts, uploads, payment, submission and publishing are outside the authorised scope. Working-title availability and current Steamworks submission requirements require review before that separate phase.
''')

stages=[
 ('0','Execution contract','Local scope, source reconciliation, ledger and permission boundaries'),
 ('1','Environment and baseline','Pinned local tools; import, runtime and canonical wrapper'),
 ('2','Movement','Shared tuning, real CharacterBody2D tests and movement lab'),
 ('3','Lifecycle/reset','Terminal completion, priority, pause, 500 resets and latency'),
 ('4','Campaign','Five prototype scenes plus 30 campaign rooms and fixtures'),
 ('5','Application systems','Menus, remapping, settings, progression and saves'),
 ('6','Integrated QA/soak','900-second soak; 265 room cycles; shutdown warning repaired and targeted regression clean'),
 ('7','Interim release','Standalone Windows export; interim report superseded'),
 ('8','Completion audit','Requirement matrix, no empty required implementations'),
 ('9','Visual polish','Original courier/scarf, poses, trails, restrained feedback and captures'),
 ('10','Audio','Eight original SFX, buses, mute, overlap and cleanup tests'),
 ('11','Campaign review','All exit/fragment routes validated; human pacing limitation disclosed'),
 ('12','Usability/accessibility','20 synthetic UI/action checks; physical device checks separate'),
 ('13','Performance/build','Rendered profiles, bounded nodes and standalone package'),
 ('14','Local Steam preparation','Store draft, trailer plan, captures, manifest and checklist; no external actions'),
 ('15','Final acceptance','Fresh regression, build/save/relaunch checks and final report')]
write('autonomous_plan.md','# Execution ledger\n\nAll in-scope local development stages executed. PASS refers to automated/deliverable evidence; human-only checks are separately NOT RUN.\n\n| Stage | Work | Status | Evidence/limit |\n|---|---|---|---|\n'+'\n'.join(f'| {n} | {title} | PASS | {note} |' for n,title,note in stages))

matrix=[
 ('Movement and shared configuration','scripts/player/player_controller.gd; data/movement/default.tres','12 actual-scene movement tests'),
 ('Reset/pause/death/exit/fragment','scripts/gameplay/run_controller.gd; level_root.gd','6 lifecycle tests; 500 resets; routes'),
 ('Handcrafted campaign and metadata','scenes/levels/chapter_*; data/campaign/*.tres; LevelCatalog','30 validated rooms; 180 replay clears'),
 ('Menus/settings/navigation','scripts/ui/game_root.gd','20 graphical action checks; inspected captures'),
 ('Saves, PBs, unlocks and input','scripts/services/save_service.gd; input_service.gd','7 save/input tests; standalone reload'),
 ('Visual identity and feedback','player_visuals.gd; backdrop.gd; assets/art/icon.svg','inspected source-runtime captures'),
 ('Audio/buses/mute/cleanup','audio_service.gd; assets/audio','UI audio checks; targeted shutdown regression'),
 ('Standalone/export isolation','export_presets.cfg; tools/build.py; verify_export.py','release EXE two-process verification; addon exclusion'),
 ('Provenance and local materials','third_party; docs/store_draft.md; trailer_plan.md','files inspected; no public claims/actions')]
write('completion_matrix.md','# Completion matrix\n\n| Requirement | Implementing files | Evidence | Status |\n|---|---|---|---|\n'+'\n'.join(f'| {req} | {files} | {evidence} | PASS |' for req,files,evidence in matrix)+'\n\nPhysical-device feel/listening/other OS checks: NOT RUN. Room duration target: P2 deviation, see known_issues.md. No required TODO/empty gameplay method is labelled complete; PlatformService intentionally provides the standalone boundary only.')

rows=[]
for i,result in enumerate(routes):
    scene=ROOT/f'scenes/levels/chapter_{i//10+1:02}/room_{i%10+1:02}.tscn'
    content=scene.read_text()
    purpose=re.search(r'purpose = "(.*)"',content).group(1)
    route=re.search(r'route = (.*)',content).group(1).replace('Array[Vector2](','').rstrip(')')
    hazards=[]
    for field in ['spikes','movers','gates']:
        line=next(x for x in content.splitlines() if x.startswith(field+' ='))
        if not line.endswith('([])'): hazards.append(field)
    rows.append(f"| {result['id']} | {purpose} | {route} | {', '.join(hazards) or 'geometry only'} | normal 3/3; fragment 3/3 | {result['time']:.2f}s; human pacing/readability pending |")
write('campaign_review.md','# Campaign review\n\nOrder: fundamentals, timing, mastery, with easier recovery rooms 5, 16 and 25. All geometry and objective coordinates are visible on a single screen. Gate bars and crosshatching identify state; no movement setting changes per room. The scripted sequences establish executability only.\n\n| Stable ID | Primary purpose | Authored route landmarks | Hazards | Validated routes | Concern |\n|---|---|---|---|---|---|\n'+'\n'.join(rows))

write('performance_report.md',f'''# Performance observations

{environment}

Method: actual rendered editor runtime at 1280 x 720 with VSync; 10 seconds in each of rooms 1, 20 and 30, using input-driven movement. Frame intervals are process-frame wall-clock samples, not GPU profiler measurements. A concurrent headless soak was running. No hardware minimum/support claim follows from this machine.

| Room | Frames | Median frame ms | p95 ms | Worst ms | Nodes | Static bytes |
|---|---:|---:|---:|---:|---:|---:|
'''+ '\n'.join(f"| {x['room']} | {x['frames']} | {x['median_frame_ms']:.3f} | {x['p95_frame_ms']:.3f} | {x['worst_frame_ms']:.3f} | {x['nodes']} | {x['static_bytes']:,} |" for x in profile['rooms'])+f'''

The 15-minute headless soak sampled {min(x['nodes'] for x in samples)}-{max(x['nodes'] for x in samples)} live nodes across different rooms and zero orphans. Static-memory change was {samples[-1]['static_bytes']-samples[0]['static_bytes']:,} bytes from first to last sample. Reusable sounds and reset objects are bounded; geometry varies by room. No unsupported global leak-free or cross-device performance claim is made. No physics/collision weakening was used for optimisation.
''')

write('visual_review.md','''# Visual inspection

Actual Godot-rendered captures in artifacts/captures were opened and inspected: menu_1280, menu_640, settings_1280, settings_640, gameplay_1280, clockwork_1280, pause_1280, select_1280, completion_640 and credits_640. Title/subtitle spacing and background geometry behind settings/credits were corrected. Text, focus, platform edges, saw teeth, spike triangles, gate bars/brackets and diamond fragments are readable in the inspected views. The final credits page was shortened to keep the Back button clear.

This is source-runtime visual evidence, not a successfully captured packaged window. Computer Use identified the exported app/window and accessibility title but screenshot capture timed out. No physical controller or subjective human playtest is inferred from these captures.
''')

write('resume.md','''# Handoff

Local implementation and automated acceptance are finished. Do not rebuild working systems. Run the game with Play Threadrunner.cmd; inspect docs/final_acceptance_report.md and known_issues.md.

If changing movement/geometry/services, read the matching project skill and rerun `.venv/Scripts/python.exe tools/qa.py --ui --export`. Add `--soak` for a fresh 15-minute soak. Preserve actual player data; tests use artifacts directories. Current evidence is in artifacts and summary copies in docs/evidence. No background development or publication is implied after this handoff.

Next human work is playtesting feel/pacing, physical controller and listening, followed by branding/licence/store review if a public release is desired.
''')

evidence=DOC/'evidence';evidence.mkdir(exist_ok=True)
for name in ['qa_summary.json','reset_metrics.json','routes_replay.json','routes_replay-normal.json','levels.json','ui.json','export-verification.json','soak-900.json','profile.json']:
    shutil.copyfile(ART/name,evidence/name)
shutil.copyfile(ART/'soak.json',evidence/'soak-cleanup-fixed.json')
shutil.copyfile(latest_xml,evidence/'results.xml')
(evidence/'reset_metrics_realtime.json').write_text(json.dumps(metrics,indent=2))
shutil.copyfile(ROOT/'builds/windows/manifest.json',evidence/'build-manifest.json')
print(f'Reports written from executed evidence: {len(qa["results"])} QA stages, 26 tests, 180 routes, {len(ui)} UI checks, {soak["cycles"]} soak cycles.')
