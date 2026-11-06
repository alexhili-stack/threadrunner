---
name: threadrunner-architecture
description: Handle Threadrunner scene, service, resource and save-boundary changes.
---

Read AGENTS.md and [docs/architecture.md](../../../docs/architecture.md) before editing.

Keep player, visuals, attempts, saves and catalog responsibilities separate. Preserve stable IDs and save compatibility. Run tools/qa.py after dependency or service changes.
