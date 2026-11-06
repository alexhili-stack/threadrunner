"""Generate the v1.1 handoff from current execution evidence only."""
from pathlib import Path
import hashlib,json,re,shutil

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artifacts';DOC=ROOT/'docs'
def load(name):return json.loads((ART/name).read_text())
def put(name,text):(DOC/name).write_text(text.strip()+'\n',encoding='utf-8')

qa=load('qa_summary.json');routes=load('routes_replay.json');normal=load('routes_replay-normal.json')
bypass=load('routes_bypass.json');ui=load('ui.json');soak=load('soak.json');reset=load('reset_metrics.json')
release=load('export-verification.json');profile=load('profile.json');integrity=load('fixture_integrity.json')
manifest=json.loads((ROOT/'builds/windows/manifest.json').read_text())
assert qa['pass'] and not qa['accelerated'] and release['pass'] and manifest['runtime_verified']
assert len(routes)==len(normal)==len(bypass)==40
assert all(x['pass'] for x in routes+normal+bypass+ui)
assert soak['duration_seconds']>=900 and not soak['failures'] and integrity['pass']
assert reset['samples']==500 and reset['worst_ms']<=250
assert manifest['build_id']=='threadrunner-1.1.0-local'
assert 'resources still in use' not in (ART/'v11-soak-output.log').read_text()
assert 'instances were leaked' not in (ART/'v11-soak-output.log').read_text()
counts=next(x for x in qa['results'] if x['name']=='test-discovery')
record_deltas=[x.get('largest_record_delta_seconds',0) for x in release['runs']]
times=[x['time'] for x in routes];early=times[:30];large=times[30:]
evidence=DOC/'evidence/v1.1';evidence.mkdir(parents=True,exist_ok=True)
for name in ['qa_summary.json','routes_replay.json','routes_replay-normal.json','routes_bypass.json','ui.json','soak.json','reset_metrics.json','profile.json','export-verification.json','fixture_integrity.json','levels.json','trap_inventory.json']:
    shutil.copyfile(ART/name,evidence/name)
shutil.copyfile(ROOT/'builds/windows/manifest.json',evidence/'build-manifest.json')
latest=max((ART/'qa-unit').rglob('results.xml'),key=lambda p:p.stat().st_mtime)
shutil.copyfile(latest,evidence/'results.xml')
rows=f'''| Check | Actual result |
|---|---|
| Canonical QA | {sum(x['pass'] for x in qa['results'])}/{len(qa['results'])} stages PASS |
| GdUnit4 | {counts['tests']} tests, {counts['failures']} failures, {counts['errors']} errors |
| Campaign metadata/spawns/reset validation | 40 rooms PASS |
| Fragment-plus-exit replay | 40 rooms x 3 = 120 clean clears |
| Ordinary exit replay | 40 rooms x 3 = 120 clean clears |
| Hold-right without jumping | 40/40 exits remain unreachable |
| Input integrity | 80 fixtures, {integrity['frames']:,} frames, zero invalid press/release edges |
| Graphical UI/input | {len(ui)}/{len(ui)} checks PASS |
| Release runtime | {sum(len(x['checks']) for x in release['runs'])} checks across two fresh processes PASS |
| Reset stress | {reset['samples']} real-time resets, median {reset['median_ms']:.3f} ms, worst {reset['worst_ms']:.3f} ms |
| Soak | {soak['duration_seconds']:.2f} seconds, {soak['cycles']} room cycles, zero failures |
'''
samples=soak['samples'];env=f"Windows; Godot 4.7.2; {profile['cpu']}; {profile['gpu']}; Compatibility renderer."
put('final_acceptance_report.md',f'''# Threadrunner 1.1 - final acceptance

**AUTOMATED ACCEPTANCE PASSED** for this local Windows x64 build. Human playtesting and physical-device/listening evidence remain unverified; this is not public-release approval.

Expanded to **40 rooms in four chapters**. Rooms 1-30 were redesigned around compulsory climbs, switchbacks, platform crossings and optional fragment detours. New rooms 31-40 are **1280x360**, twice the original width, with a bounded following camera; the logical viewport remains 640x360. Shared physics values are unchanged.

Five pilots (1, 4, 8, 13, 30) established jumping, precision, wall, timing and mastery routes before the full campaign expansion. Their final captures and routes are in artifacts/captures/pilot_* and campaign_review.md. Every wall-route replay emits wall jumps; every designated variable-jump replay contains an early release. No teleports, disabled hazards or direct fragment grants were used.

Added ceiling teeth and telegraphed hot-air vents alongside spikes, saws and gates. Vents have a safe amber warning phase, gates signal approaching closure, and all trap phases reset with attempts. Four original 24-second ambient compositions, distinct chapter backdrops, clearer movement/death/collection/exit feedback, room previews, visible PB/fragment details, completion-time comparisons, adaptive controller prompts and a persistent deadzone slider are implemented.

Save schema 2 preserves unlocks/completions/fragments/settings and archives old-layout PBs. Previous times cannot compete with the larger redesigned layouts. A zero current-time marker denotes a historical completion until a new-layout time is recorded.

{rows}

{env} Full command: `.venv/Scripts/python.exe tools/qa.py --ui --export`. A separate 900-second run used `tools/soak.gd` with isolated test saves and a 1200-second process timeout. `tools/polish_gallery.gd` captured the five pilots and warning/active vent states. `tools/profile.gd` measured rooms 1, 30 and 40 at a 120 FPS cap with fixture input at 60 Hz. Structured evidence: docs/evidence/v1.1/; full logs: artifacts/.

Redesigned rooms 1-30: scripted fragment clear range {min(early):.2f}-{max(early):.2f} seconds, mean {sum(early)/30:.2f}. Larger rooms: {min(large):.2f}-{max(large):.2f} seconds, mean {sum(large)/10:.2f}. These are executable input routes, not human first-clear or difficulty claims.

The standalone EXE cleared six representative rooms (1, 4, 8, 13, 30, 40), collected fragments, showed completion, restarted, wrote saves, quit and loaded progress in another process. Test add-ons/fixtures are excluded from the package and normal menus. Explicit CLI verification accepts external input fixtures through the same gameplay controller. JSON record values are compared within one microsecond; largest observed round-trip difference was {max(record_deltas):.18g} seconds. Record IDs/counts remain exact.

Build ID: {manifest['build_id']}. Source SHA-256: `{manifest['source_sha256']}`. EXE SHA-256: `{manifest['files']['Threadrunner.exe']['sha256']}`. PCK SHA-256: `{manifest['files']['Threadrunner.pck']['sha256']}`. Current build: builds/windows/Threadrunner.exe + Threadrunner.pck; portable ZIP: builds/Threadrunner-Windows.zip. The original Windows ZIP is preserved as Threadrunner-1.0.0-Windows.zip. Source remains uncommitted; no Git history was fabricated.

Physical controller/unplug testing, subjective audio listening, human feel/fairness, other OS/device support and Steam account/publication work are NOT RUN. Synthetic events and actual rendered source-runtime captures were checked. No payments, uploads, account actions or publishing occurred.
''')
put('qa_report.md',f'''# Threadrunner 1.1 QA

AUTOMATED ACCEPTANCE PASSED. {env}

{rows}

The complete real-time wrapper, separate 15-minute soak, graphical checks and standalone launch/relaunch all executed. Logs and failure-probe results are retained in artifacts; current summary evidence is in docs/evidence/v1.1. The intentionally failing framework probe returns 100, and zero discovered coverage is rejected.

Early verification exposed floor bypasses, premature route acceptance, fixture press/release inconsistencies and an overly strict binary-equality save assertion. The final geometry blocks all tested hold-right attempts, fixtures have valid input edges, and save comparisons enforce exact record identities plus a one-microsecond numeric tolerance. Largest observed numeric difference: {max(record_deltas):.18g} seconds.

Soak nodes ranged {min(x['nodes'] for x in samples)}-{max(x['nodes'] for x in samples)} across different room geometries, with a maximum {max(x['orphans'] for x in samples)} orphan nodes. First/last static-memory samples: {samples[0]['static_bytes']:,}/{samples[-1]['static_bytes']:,} bytes. Music uses two reusable players, effects eight. No shutdown resource-leak warning was logged in this soak. These measurements do not establish universal leak freedom.

Human game feel, physical controller compatibility and audio quality remain NOT RUN. No current execution is implied after handoff.
''')
put('known_issues.md',f'''# Known limits - v1.1

- No unresolved automated P0/P1 was observed in final acceptance.
- Earlier rooms intentionally remain compact: scripted fragment routes range {min(early):.2f}-{max(early):.2f}s. Human pacing/difficulty review is pending. Larger rooms range {min(large):.2f}-{max(large):.2f}s.
- Keyboard/controller action paths, drift thresholds, pause/focus callbacks and fullscreen transitions passed synthetic tests. Physical controller/driver/unplug behaviour is NOT RUN.
- Music/SFX routing and bounded playback were tested; subjective listening quality is NOT RUN.
- Source-runtime screenshots were inspected at 1280x720 and 640x360, including actual scrolling-camera traversal. A successful native packaged-window screenshot is not claimed; standalone gameplay was verified separately.
- Windows x64 is the tested target. macOS/Linux/Steam Deck and Steam features are unverified/unimplemented.
- Exact binary equality is not required for JSON floating-point PBs; tests enforce a one-microsecond limit and exact keys. Previous-layout PBs remain archived separately.
''')
put('blockers.md','''# Remaining boundaries

No local implementation or tool-install blocker remains for the authorised Windows build. Human game-feel/difficulty review, physical controller/unplug testing, subjective listening, branding/licence review and any future Steam-account work remain separate. No external publication is authorised.
''')
put('improvement_plan.md','''# Threadrunner 1.1 improvement ledger

1. PASS - preserved original source/evidence and Windows ZIP.
2. PASS - five pilot rooms established required jumping, precision, wall, timing and mastery routes; captures inspected.
3. PASS - applied the design across the original thirty rooms; user-requested expansion adds ten larger scrolling rooms for forty total.
4. PASS - added ceiling teeth, telegraphed vents, gate warnings, chapter backdrops, four original music loops and bounded character/collection/exit feedback.
5. PASS - previews, names, current PBs/fragments, completion comparisons, adaptive prompts, deadzone and old-save migration.
6. PASS - full real-time QA, 240 route clears, 40 bypass attempts, graphical checks, 500 resets, 15-minute soak, Windows rebuild/runtime verification and final evidence.

Physical-device, subjective listening and human playtesting remain NOT RUN, not automated passes. Shared movement values remain unchanged. No dependencies or movement mechanics were added.
''')
put('autonomous_plan.md','''# Current execution ledger

The original Stage 0-15 workflow is preserved in artifacts/v1-baseline/source-and-evidence.zip. The implemented v1.1 improvement/expansion work is complete; see improvement_plan.md and final_acceptance_report.md for current evidence. All local implementation/testing/export tasks passed. Human-only checks remain separately NOT RUN.
''')
review=[]
for i,item in enumerate(routes):
    source=(ROOT/f'scenes/levels/chapter_{i//10+1:02}/room_{i%10+1:02}.tscn').read_text()
    purpose=re.search(r'purpose = "(.*)"',source).group(1)
    review.append(f"| {i+1:02d} / {item['id']} | {purpose} | {'1280x360' if i>=30 else '640x360'} | 3/3 normal; 3/3 fragment; bypass blocked | {item['time']:.2f}s |")
put('campaign_review.md','# Campaign review - 40 rooms\n\nFive pilots: 1, 4, 8, 13, 30. Teach/practise/combine progression includes quiet recovery rooms and a ten-room larger expert chapter. Fragments are optional and only persist on same-attempt completion. All reported routes drive the actual controller. Human fairness remains unassessed.\n\n| Room | Teaching purpose | Size | Evidence | Scripted fragment time |\n|---|---|---|---|---|\n'+'\n'.join(review))
put('completion_matrix.md','''# Completion matrix - v1.1

| Requirement | Implementation | Evidence | Status |
|---|---|---|---|
| Forty rooms, ten larger | scenes/levels; data/campaign; LevelCatalog.COUNT | 40-scene validation and 240 clears | PASS |
| Required skill routes | authored switchbacks/shafts/platforms | wall/early-release event checks; 40 bypass rejections | PASS |
| Traps and warnings | LevelRoot ceiling_spikes/vents/gates/movers | hazard tests, reset tests, route fixtures and captures | PASS |
| Shared movement | MovementConfig and PlayerController | 12 movement tests; unchanged values | PASS |
| Menu previews/records | RoomPreview and GameRoot | graphical UI checks/captures | PASS |
| Music and feedback | AudioService, PlayerVisuals, chapter WAVs | bounded players, routing and soak | PASS |
| Input/accessibility | InputService, settings, fixed UI canvas | deadzone/remap/focus/fullscreen synthetic tests | PASS |
| Save compatibility | schema 2/layout revision 2 | legacy migration, current records and standalone reload | PASS |
| Camera and world bounds | LevelRoot.world_size / Camera2D | camera follows actual traversal; bounds/reset tests | PASS |
| Windows release | build/verify scripts and preset | separate release processes and checksums | PASS |
| Human/physical/audio quality | human playtest | unavailable human/device evidence | NOT RUN |
''')
put('visual_review.md','''# Visual review - v1.1

Inspected actual rendered source-runtime captures: pilot_01_start/mid, pilot_04_mid, pilot_08_start, pilot_13_start, pilot_30_mid, vent_warning, vent_active, gameplay_1280, settings_640, select_large_640 and afterlight_scrolling_640. Five pilots show the revised vertical/return routes. Vents use a distinct amber warning dot and coral upward plume; gates show crosshatching and closing warnings. Chapter palettes/decorations remain subdued behind landing surfaces and coral lethal shapes.

Selection previews, titles, PB/fragment details and all four chapter rows fit the 640x360 layout. The larger room's HUD stays screen-fixed while its world scrolls. No physical controller or subjective sound-quality result is inferred from these captures. No successful packaged-window screenshot is claimed.
''')
put('performance_report.md',f'''# v1.1 performance observations

{env} Resolution: {profile['resolution']}. Method: {profile['method']}. Measurements are editor-runtime process-frame intervals, not GPU presentation or universal hardware requirements. The soak ran concurrently.

| Room | Median ms | p95 ms | Worst ms | Nodes | Static bytes |
|---|---:|---:|---:|---:|---:|
'''+ '\n'.join(f"| {x['room']} | {x['median_frame_ms']:.3f} | {x['p95_frame_ms']:.3f} | {x['worst_frame_ms']:.3f} | {x['nodes']} | {x['static_bytes']:,} |" for x in profile['rooms'])+f"\n\nSoak: {soak['cycles']} cycles, {soak['duration_seconds']:.2f}s, zero gameplay failures. Live-node counts vary by room; no orphan growth was observed in the recorded samples.\n")
put('resume.md','''# Handoff

The authorised improvement and expansion work is finished. Launch Play Threadrunner.cmd or builds/windows/Threadrunner.exe. Read final_acceptance_report.md and known_issues.md. The previous Windows ZIP is preserved separately.

For future source changes, run `.venv/Scripts/python.exe tools/qa.py --ui --export`; add `--soak` for a fresh 15-minute run. Fixtures are regenerated using tools/route_runner.gd record/normal modes and validated for input edges. Keep original authoring scripts from overwriting later scene edits without review. No background development or publication continues after handoff.
''')
print('v1.1 reports generated:',counts['tests'],'tests, 240 clears,',len(ui),'UI checks,',soak['cycles'],'soak cycles.')
