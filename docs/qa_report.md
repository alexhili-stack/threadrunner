# Threadrunner browser edition and refinement verification

The browser edition exports the shared Godot 4.7.2 game to single-threaded WebAssembly. The room geometry, stable IDs and `data/movement/default.tres` are unchanged. The Windows 1.2 release below remains a separate frozen artifact.

Executed on 2026-11-06:

- Shared-code checks: 49 unit cases with zero failures/errors, failure/empty-suite probes, 45 scene validation, 85 fixture validation, 255 successful campaign/lesson replay clears and negative attempts passed.
- The empty-rewind hover regression was reproduced against the actual CharacterBody2D, then fixed. All 13 thread tests pass, including gravity after exhaustion, release before reuse, reset and preview/action agreement.
- Actual WebAssembly release: 410/410 checks passed. All 45 fragment routes cleared three times with zero deaths; completion pages, restarts, 45 saved IDs, save round trips and development-addon exclusion passed. The opt-in accelerated local verifier retained a 1/60-second physics step. Its maximum record round-trip error was 1.78e-15 seconds.
- Static browser candidate: 23 files, 41,522,024 bytes before the manifest; no tests, fixtures or native executables. Both browser scripts parse and build/serve/setup/QA Python tools compile.
- Local Chromium: game boot, native menus, keyboard movement/jump, touch-button movement and pause/resume observed. Browser settings persisted after a fresh reload (mute On); IndexedDB reported persistent storage. Error/warning capture was empty during the checked sessions.
- Layout inspected at the normal desktop viewport, 390x844 and 844x390. Fullscreen entry was observed. Responsive thumb groups, automatic touch visibility, tool readiness and external lesson objectives were checked. Physical phones, Safari, physical controllers, subjective listening and full screen-reader support are NOT RUN.
- GitHub Pages: the initial hosted build/export passed; deployment required enabling Pages with GitHub Actions, after which run 42290486960 succeeded. Refinement run 42294765639 built and deployed successfully from commit 0f4bb72375aa9d2ae690b6959f7808c978854ee5. The live manifest matches that revision, the player/host/game-pack hashes match the manifest, and WebAssembly is served with application/wasm (HTTP 200). The published game was opened in Chromium: the new lesson objective and touch groups rendered, held touch input moved the courier from x=40 to x=69.667, and browser error/warning capture was empty. The accepted hosted screenshot is artifacts/web/threadrunner-live.jpg.
- Final canonical report: PASS after the retained targeted static and graphical rechecks. All 33 graphical assertions passed in a fresh report. The real-time headless soak ran 917.099 seconds over 82 room cycles with zero failures.

The first browser verifier run found one early completion-UI assertion while all 135 gameplay clears passed. The verifier now waits until Node._process has handled its pending screen transition; the full 410-check rerun passed without removing an assertion. Both reports are retained in artifacts/web. A touch focus transfer was removed after a held-input check exposed it.

The current full canonical run initially reported a lint limit and a graphical process exited before producing its full report. The return structure was simplified, and tools/qa.py now requires a fresh report containing at least 33 passing graphical checks, preventing early process exits from being accepted. Targeted rechecks preserve prior results and logs in the audit history.

Evidence is retained in artifacts/qa_summary.json, unit XML, artifacts/web/browser-replays.json, artifacts/web/settings-reloaded.json and artifacts/design-audit. The UI review is documented in docs/browser_design_review.md.

# Threadrunner 1.2 — local acceptance

Verified local Windows x64 build: **threadrunner-1.2.0-local**. The game now has a rebuilt native interface and all three requested thread tools, across forty campaign rooms and five new Threadwork lessons.

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
| GdUnit4 discovery and assertions | 46 cases, 0 failures, 0 errors |
| Failure and empty-suite probes | Expected failure exits 100; empty coverage rejected |
| Level validator | 45 scenes, no issues |
| Input consistency | 85 files, 57,144 frames, no issues |
| Real-controller campaign routes | 40 fragment and 40 ordinary routes × 3, all clear |
| Real-controller thread lessons | 5 routes × 3, all clear with fragments and zero deaths |
| Total successful route replays | 255 |
| Negative attempts | 40 hold-right/no-jump bypasses and five no-tool lesson walks rejected |
| Graphical input/UI checks | 33/33 PASS |
| Retry stress | 500 resets; median 96.629 ms, worst 103.548 ms; no node increase, 0 orphans |
| Real-time headless soak | 917.12 seconds, 82 room cycles, 0 recorded failures |
| Standalone Windows processes | Eleven fragment clears, completion pages, restarts, save/relaunch and test-addon exclusion; 43/43 checks PASS |
| Packaged graphical backend | OpenGL initialized, menu/save/test-addon smoke 5/5 PASS, clean exit 0; muted isolated test window |
| Portable ZIP | CRC, EXE/PCK hashes and both font notices verified |

The initial graphical run correctly paused when the research browser took foreground focus. Its completion-page assertion failed. An isolated diagnostic rerun reproduced a successful clear, and a canonical targeted UI recheck passed all assertions. The prior result is retained in qa_summary.json's recheck history and the evidence directory; no assertion was removed or weakened.

The full soak began before the final presentation-only HUD rail, prompt placement and state-color corrections. Movement, tool physics, collision geometry, hazard timing and route fixtures were unchanged. Final presentation and remapping-aware lesson copy were checked graphically; the final exported PCK was separately exercised through its standalone processes.

## Render and timing review

Actual Godot graphical captures at 640 × 360 and 1280 × 720 were inspected for menu, selection, settings, pause, completion, credits, campaign rooms and active tool states. The independent finishing reviewer validated 17 captures, requested one compact-HUD correction, then scored that fix resolved with no visible batch regressions. Its final **ship** disposition covers that scored fix, not an unperformed human playtest. Durable tokens are in DESIGN.md and .impeccable/design.json.

Frame intervals were sampled for ten seconds each on Windows, AMD Ryzen 9 3900X 12-Core Processor, NVIDIA GeForce RTX 3070, 1280 × 720, GL Compatibility, 120 FPS cap, while the headless soak ran concurrently. These are process-frame intervals; GPU presentation was not measured.

| Room | Median frame interval | 95th percentile | Worst interval |
|---|---:|---:|---:|
| 1 | 8.261 ms | 9.078 ms | 23.575 ms |
| 30 | 7.473 ms | 9.669 ms | 10.133 ms |
| 40 | 7.156 ms | 9.966 ms | 10.273 ms |
| 45 | 7.603 ms | 9.388 ms | 28.564 ms |

## Not run / limits

Human difficulty/fun and keyboard/controller feel, subjective listening, a physical controller and hardware unplug, other operating systems, and store/public-release checks were NOT RUN. Synthetic controller events and explicit disconnect/focus-loss handlers were tested; they are not physical-hardware evidence. No publishing, account action or system-wide installation occurred.

The native Windows capture API timed out on the packaged OpenGL window and the window was absent on its retry. Therefore no packaged-window screenshot is claimed. A fresh isolated graphical-backend process subsequently initialized OpenGL and passed five smoke checks with clean exit 0. The inspected full screenshots come from the actual graphical Godot source runtime, not a mockup.

## Build and evidence

- Play: builds/windows/Threadrunner.exe beside Threadrunner.pck, or Play Threadrunner.cmd.
- Portable package: builds/Threadrunner-Windows.zip; a versioned 1.2 copy is preserved alongside 1.0 and 1.1.
- Manifest source SHA-256: `106b6a0339263067e2905b3480781e1cd439d0bb2485f8a4f4f3ad7316fb4984`. Live source and package files match it.
- Machine-readable evidence and unit XML: docs/evidence/v1.2. Full process logs remain in artifacts.
- Research: docs/visual_research.md. Mechanic details: docs/thread_tool.md. Rights: docs/asset_provenance.md and third_party/fonts.
