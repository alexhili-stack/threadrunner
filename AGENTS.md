# Threadrunner

Build the standalone Godot 4.7.2 precision platformer described in docs/game_design.md.
The user authorised the minimal project-local engine, GdUnit4 and gdtoolkit installation.
Keep movement in CharacterBody2D physics and data/movement/default.tres; never change physics per room.
Separate visuals, attempts, saves, and level metadata. Preserve stable room IDs.
Use tools/qa.py for evidence; record actual outcomes and unavailable checks in docs/qa_report.md.
Read the relevant .agents/skills/threadrunner-* workflow when modifying its subsystem.
No publishing, account actions, credentials, system-wide installs, or unrelated dependencies.
