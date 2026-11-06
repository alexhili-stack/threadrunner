---
name: threadrunner-qa
description: Handle Threadrunner gameplay regressions and milestone verification.
---

Read AGENTS.md and [docs/acceptance_tests.md](../../../docs/acceptance_tests.md) before editing.

Run tools/qa.py; preserve logs and discovered test counts in artifacts. Report executed PASS/FAIL and unavailable NOT RUN separately. Never weaken valid assertions to get green. Stop after three materially different failed repair approaches and record the blocker.
