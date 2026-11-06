# Threadrunner

Carry the last signal. An original precision platformer with 40 campaign rooms and five Threadwork lessons: stitch bridges, power relays, swing from anchors, and rewind along the thread you leave behind.

![Threadrunner main menu](docs/screenshots/threadrunner-menu.png)

## Download and play

**[Download Threadrunner for Windows x64](https://github.com/alexhili-stack/threadrunner/releases/latest/download/Threadrunner-Windows.zip)**

1. Download `Threadrunner-Windows.zip` from [Releases](https://github.com/alexhili-stack/threadrunner/releases).
2. Right-click the ZIP and choose **Extract All**.
3. Open the extracted `Threadrunner` folder and run **Threadrunner.exe**. Keep `Threadrunner.pck` and `third_party` alongside it.

No Godot editor, Python, installation or GitHub account is needed to play. Choose **Thread lessons** from the main menu to learn the tools. The green **Code → Download ZIP** button contains source code; use the Windows release asset to play.

To share with friends, send the release link or the complete Windows ZIP. Sending just the EXE leaves out the game data. Progress saves locally on each player's computer.

## Controls

| Action | Keyboard | Controller |
|---|---|---|
| Move | A / D or arrows | Left stick / D-pad |
| Jump / release grapple upward | Space / Up | A |
| Stitch bridge / power relays | E | X |
| Grapple / release | F | B |
| Rewind laid trail | Hold Shift | Hold LB |
| Retry | R | Y |
| Pause / back | Esc | Start / B in menus |

F11 toggles fullscreen. Settings include keyboard remapping, stick deadzone, separate audio levels and reduced decorative effects. Rewind follows up to six seconds of your real trail; time and hazards continue. Gold fragments count when you finish the same attempt.

![Swinging on a thread](docs/screenshots/threadrunner-grapple.png)

## Source and development

Built with **Godot 4.7.2**, GdUnit4 6.2.2 and gdtoolkit 4.5.0. Open `project.godot` with the pinned engine. Development add-ons and license notices are included; downloaded engines, Python environments, generated imports, build binaries, test saves and private source documents are excluded from Git.

Project-local setup and export: [Build and run](docs/build_and_run.md). Run `.venv/Scripts/python.exe tools/qa.py --ui --soak --export` for the full Windows checks. Setup tools are in `tools/install_tools.py` and `tools/install_export_template.py`. Authoring scripts can replace level data; read them before rerunning.

See [thread mechanics](docs/thread_tool.md), [architecture](docs/architecture.md), [design research](docs/visual_research.md) and [verified QA results](docs/public_qa.md).

## Status and credits

Version 1.2.0 is a standalone Windows x64 local build. macOS, Linux and Steam Deck builds are not provided. Automated verification passed 46 unit tests, 255 route clears, 33 graphical checks, a 917-second soak and standalone save/relaunch checks. Human difficulty, physical-controller feel and listening remain playtest tasks.

Design and implementation: Alexander Hili with Codex. Original vector art and synthesized audio. Barlow Condensed and Manrope fonts use SIL OFL 1.1. Godot, GdUnit4 and gdtoolkit retain their own licenses in `third_party`. The project's original code/assets do not yet have a separately specified open-source license.
