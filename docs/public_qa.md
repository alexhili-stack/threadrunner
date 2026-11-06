# Electric Foundry 1.4 — current verification

The selected dark foundry world is applied across all 45 rooms. Gameplay contains only an icon pause control and a small history rail; bindings and lesson objectives live in Pause → How to play. Geometry, stable room IDs, movement and saves are preserved.

| Check | Result |
|---|---|
| Canonical QA, including final targeted rechecks | PASS |
| Unit tests | 49 cases; zero failures/errors |
| Scene/fixture validation | 45 scenes, 85 fixtures |
| Native route replays | 255 clears; 40 no-jump and 5 no-tool negative attempts rejected |
| Native graphical UI | 38/38 assertions passed |
| Real-time soak | 917.056 seconds, 82 room cycles, zero failures |
| Windows 1.4 local standalone build | 43/43 checks passed; rebuilt ZIP; public 1.2 download remains separate |
| Browser release controller replays | 410/410 checks; 45 fragment routes × 3 and saved-progress roundtrip |
| Manual browser checks | Keyboard, held-touch movement, pause/help/back; desktop 1672×941 and portrait 390×844 |
| Visual review | Selected source compared with actual renders; both scored fixes resolved; design-qa.md passed |

Incomplete graphical reports, diagnostic-script parse and input-timing failures are retained locally. The 38-check gate was preserved; the final synthetic keys wait for GUI processing and physics ticks. Physical phones, Safari, physical controllers, subjective listening, human difficulty and full screen-reader compatibility were not tested.

The selected concept and generation provenance are included in docs/design and docs/foundry_asset_provenance.json. Unavailable design-launcher/detector/process inputs are disclosed; no unperformed detector result is claimed.

The Foundry browser build is live at [Play Threadrunner](https://alexhili-stack.github.io/threadrunner/). [GitHub Actions run 42301397798, attempt 2](https://github.com/alexhili-stack/threadrunner/actions/runs/42301397798/attempts/2) deployed commit `bb65db092146f0ca0877f2193408ce3dac15b398`. The first deployment stalled at file synchronization and was canceled; its retry succeeded. Hosted HTML, JavaScript, CSS, host adapter and game-pack hashes match the new manifest. WebAssembly returns HTTP 200 with application/wasm. Actual hosted keyboard movement, bridge stitching, pause, focused help with the current objective, back and resume were verified; no captured console errors. Empty browser utilities and help stay hidden during play.

# Browser edition 1.3 — previous verification

| Check | Result |
|---|---|
| Shared-code canonical QA | PASS after retained targeted rechecks |
| GdUnit4 | 49 tests, zero failures/errors |
| Campaign and lesson replays | 255 successful clears, negative attempts rejected |
| Browser WebAssembly release | 410 checks passed; all 45 rooms cleared three times with fragments and zero deaths |
| Browser save round trip | All 45 stable IDs; maximum time difference 1.78e-15 seconds |
| Fresh browser reload | Saved mute preference retained; persistent IndexedDB available |
| Native graphical UI | Fresh report: 33 passing checks |
| Real-time headless stability | 917.099 seconds, 82 room cycles, zero failures |
| Responsive review | Desktop, 390x844 and 844x390; touch movement and pause observed |

An empty-rewind hover bug was reproduced and fixed without changing the shared movement tuning or room geometry. New tests cover falling after exhaustion, releasing before reuse and stitch-target agreement. A completion-screen verification race was fixed by waiting for rendered UI; all original assertions remained. The first incomplete native graphical process and a lint failure are retained in local audit history; fresh targeted rechecks passed. QA now rejects early graphical exits without a complete report.

Physical phones, Safari, physical controllers, subjective listening and full screen-reader compatibility were not tested. Godot canvas menus have accessibility limits. The existing Windows 1.2 release below is a separate frozen artifact.

The refined browser build is live at https://alexhili-stack.github.io/threadrunner/. [GitHub Actions run 42294765639](https://github.com/alexhili-stack/threadrunner/actions/runs/42294765639) built and deployed commit `0f4bb72375aa9d2ae690b6959f7808c978854ee5`. Hosted player, host script and game-pack hashes match its manifest; the WebAssembly response is HTTP200 with application/wasm. Documentation-only commits do not rebuild the game.

# Threadrunner 1.2.0 — verified build

| Check | Result |
|---|---|
| Formatter, linter, editor import | PASS |
| GdUnit4 | 46 tests, zero failures/errors |
| Real-controller replay routes | 255 successful clears |
| Negative attempts | 40 no-jump bypasses and five no-tool lesson walks rejected |
| Scene and fixture validation | 45 scenes, 85 input fixtures |
| Graphical input/UI | 33 checks passed at 640×360 and 1280×720 |
| Retry stress | 500 resets; median 96.629ms, worst 103.548ms; no node growth or orphan nodes |
| Stability soak | 917.118 seconds, 82 room cycles, no recorded failures |
| Windows release | Eleven rooms, completion UI, restarts and save/relaunch; 43 checks passed |
| Packaged graphics smoke | OpenGL initialized; five checks and clean exit |
| Portable ZIP | CRC and executable/game-data hashes verified |

An initial graphical run paused on application focus loss during research. Its failed completion assertion was retained in the local audit history; the isolated canonical recheck passed without removing or weakening assertions. A final presentation-only HUD correction was separately reviewed and graphically rechecked; tool physics and geometry did not change.

Full machine-local logs, XML, paths and test-save directories remain local. This public summary records their verified outcomes. Native capture of the packaged OpenGL window timed out; inspected screenshots came from the real graphical source runtime. Human difficulty/fun, physical-controller feel, hardware unplug and subjective listening were not tested.

The Windows ZIP SHA-256 is `f7b14da01975ffc0ab0da80fdd16fa791c0305073adcebe60a6fccfa70213a6a`. Release assets also include a checksum file.
