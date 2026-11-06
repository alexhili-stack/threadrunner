# Acceptance

Run `.venv/Scripts/python.exe tools/qa.py` from the project. Use `--quick` for accelerated iteration. The standard run uses real-time physics for the unit/lifecycle stress suite. `--soak` adds 900 seconds of live gameplay with a 1200-second process timeout; `--export` produces a Windows release when the pinned local template is installed.

Required evidence: formatter and lint; editor import and runnable baseline; all 34 required GdUnit4 tests and zero failed assertions/errors; actual player movement tests; lifecycle/reset stress; saves/input tests; level validator; all 40 recorded fragment-plus-exit routes replayed three times. The wrapper separately demonstrates a controlled failing test has a nonzero result and rejects zero discovered tests. Logs and XML remain in artifacts; summary results are copied to docs.

Visual inspection uses actual rendered captures. Graphical UI synthetic-event tests and export launch evidence are separate from headless tests. Human keyboard/controller feel, listening, hardware disconnect, other OS support and commercial readiness remain distinct checks.

Version 1.1 additionally requires 40 hold-right/no-jump rejections, 80 fixture input-edge validations, real wall-jump/short-release evidence where required, large-camera traversal, schema migration and separate release-process save checks.

Version 1.2 requires at least 46 discovered unit tests, 85 consistent fixtures, 45 validated scenes, the original 240 route clears and 40 negative bypass runs, plus 15 thread-lesson clears and five no-tool rejections. Graphical checks include thread action bindings and controller B context. The release verifier covers six original rooms plus all five thread lessons in the actual shipped executable.
