# Browser edition and refinement verification

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

The refined browser build is live at https://alexhili-stack.github.io/threadrunner/. [GitHub Actions run 42294765639](https://github.com/alexhili-stack/threadrunner/actions/runs/42294765639) built and deployed commit `0f4bb72375aa9d2ae690b6959f7808c978854ee5`. Hosted player, host script and game-pack hashes match its manifest; the WebAssembly response is HTTP 200 with application/wasm. Documentation-only commits do not rebuild the game.

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
