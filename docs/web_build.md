# Browser build

Play at **https://alexhili-stack.github.io/threadrunner/**. No installation or GitHub account is needed. Click **Play in browser**, then choose **Begin the run** or **Thread lessons**. The first visit downloads approximately 42 MB; later loads can use the browser cache.

The same Godot 4.7.2 scenes, CharacterBody2D controller, movement resource and 45 stable room IDs are exported to WebAssembly. The Web preset uses the GL Compatibility renderer and the single-threaded release template, so GitHub Pages needs no custom isolation headers. It does not install a service worker.

## Playing

Keyboard and controller mappings match the Windows version. The player also offers touch buttons, pause/resume and fullscreen. On smaller screens, landscape orientation gives the game more room. Jump releases a grapple upward; hold Rewind to follow the actual trail. Browser and device performance vary; WebGL 2 is required.

Progress and settings live in this browser's local storage through Godot's IndexedDB filesystem. Clearing site data removes them. Private browsing or restricted storage may prevent persistence; the player reports when storage is unavailable. Browser saves are independent of the Windows release and other browsers or devices. Switching tabs pauses gameplay. Audio starts after interaction with the player.

## Reproduce locally

Use the pinned project-local engine, then run:

```powershell
.venv/Scripts/python.exe tools/install_web_template.py
.tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import --quit
.venv/Scripts/python.exe tools/build_web.py
.venv/Scripts/python.exe tools/serve_web.py
```

Open `http://127.0.0.1:8063/`. Serve the files over HTTP; opening the HTML as a local file cannot load WebAssembly correctly. The installer downloads only the official pinned Web template member, verifies its SHA-256 and ZIP CRCs, and records provenance. No system-wide installation is needed.

The static output is `builds/web`, including `manifest.json` with the source commit and every deployed file's SHA-256. Development add-ons, tests, route fixtures and native executables are excluded.

## Deployment

`.github/workflows/pages.yml` builds on game-source pushes to `main` and can be run manually. Documentation-only pushes are excluded. It verifies the pinned Linux engine, installs the pinned Web template, imports resources, exports the game and deploys the static artifact with the official GitHub Pages actions. Repository Settings → Pages uses **GitHub Actions** as its publishing source. The existing Windows release remains available separately.

## Verification

Run the canonical `tools/qa.py` for shared-code regressions. For browser replays, start `tools/serve_web.py --qa`, visit `http://127.0.0.1:8063/?qa=1` and click Play. Only the local server supplies the input bundle; it is never included in the deployment. The verifier drives the real controller through all 45 fragment routes three times, checks zero-death clears, completion pages, restart state and save round trips, then writes its result into the page's `qa-report` element. The optional accelerated local verifier preserves a 1/60-second physics step; ordinary play always uses the project's normal physics timing. Manual browser input, storage/reload, layout and the hosted deployment are checked separately.
