---
name: threadrunner-movement
description: Handle Threadrunner controller, collision, jump timing or MovementConfig changes.
---

Read AGENTS.md and [docs/movement_spec.md](../../../docs/movement_spec.md) before editing.

Use tests/movement/test_player.gd against the actual CharacterBody2D. Reproduce the failure before editing. Keep one tuning Resource; never change physics per room. Run movement plus lifecycle and route regressions.
