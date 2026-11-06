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
