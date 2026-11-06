# Build and run

Double-click `Play Threadrunner.cmd` or launch `builds/windows/Threadrunner.exe`. Distribution: extract `builds/Threadrunner-Windows.zip` and run the executable beside its PCK. No Python, editor, test add-on or development tooling is needed to play the export.

Source editor: `.tools/godot/Godot_v4.7.2-stable_win64.exe --editor --path .`

QA: `.venv/Scripts/python.exe tools/qa.py --ui --export`.
Add `--soak` for a 900-second soak with a 1200-second timeout. Use `--quick` for accelerated iteration. Every subprocess has a timeout and logs; the wrapper rejects failures and zero discovered coverage. XML reports are under artifacts/qa-unit. Deliberate failure/zero-test probes are expected setup diagnostics, not accepted gameplay failures.

Build alone: `.venv/Scripts/python.exe tools/build.py`. It uses the project-local pinned Windows x64 release template, creates the EXE/PCK, copies notices and packages the portable ZIP. The build manifest records hashes; runtime verification is a separate operation.

Source route replay: `.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --fixed-fps 60 --script tools/route_runner.gd -- --mode=replay`.
Use `--mode=replay-normal` for exit-only fixtures. `record` and `normal` are authoring tools and overwrite only their fixture set after a successful physical route.

Graphics and user-data checks require normal Windows runtime access. The restricted agent sandbox can block the Windows certificate store, shader cache and user-data discovery. These are recorded environment errors; final graphical/build validation is run with authorised normal runtime access. CLI logs always use explicit project-local files, and test saves use artifacts directories.

Installer recovery: run the bundled Python interpreter against tools/install_tools.py to recreate .tools/godot, addons/gdUnit4 and .venv. tools/install_export_template.py fetches only the Windows release member from the official multi-platform template archive, verifying its ZIP CRC. Resolved dependencies and licence locations are in tools/dependencies.lock.json and tools/requirements-resolved.txt. No global software, PATH or Codex configuration was modified.

Version 1.1 has 40 rooms, 10 at 1280x360 with a bounded camera. The preserved v1 ZIP is builds/Threadrunner-1.0.0-Windows.zip. New scene authoring lives in tools/refine_campaign.py; review before rerunning it. fixtures must pass tools/validate_fixtures.py. Current evidence is in docs/evidence/v1.1.

Version 1.2 adds a usable thread and five Threadwork lessons, for 45 rooms total. Both earlier ZIPs are preserved. Scene-authoring tools/add_thread_missions.py is not a runtime generator; review before rerunning. Thread fixtures have six input columns and are verified with tools/thread_routes.gd. A targeted graphical recheck is available through tools/qa.py --recheck-ui after a complete report; its audit history retains the previous result. Current evidence: docs/visual_acceptance_report.md and docs/evidence/v1.2.
