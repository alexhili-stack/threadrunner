# Known limits - v1.1

- No unresolved automated P0/P1 was observed in final acceptance.
- Earlier rooms intentionally remain compact: scripted fragment routes range 7.82-13.17s. Human pacing/difficulty review is pending. Larger rooms range 17.55-23.57s.
- Keyboard/controller action paths, drift thresholds, pause/focus callbacks and fullscreen transitions passed synthetic tests. Physical controller/driver/unplug behaviour is NOT RUN.
- Music/SFX routing and bounded playback were tested; subjective listening quality is NOT RUN.
- Source-runtime screenshots were inspected at 1280x720 and 640x360, including actual scrolling-camera traversal. A successful native packaged-window screenshot is not claimed; standalone gameplay was verified separately.
- Windows x64 is the tested target. macOS/Linux/Steam Deck and Steam features are unverified/unimplemented.
- Exact binary equality is not required for JSON floating-point PBs; tests enforce a one-microsecond limit and exact keys. Previous-layout PBs remain archived separately.
