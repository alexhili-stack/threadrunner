# The usable thread

The user explicitly requested all three proposed actions on 6 November 2026. They are available throughout the campaign with one shared MovementConfig.

| Action | Keyboard default | Controller | Behavior |
|---|---|---|---|
| Stitch | E | X | Near a square terminal, toggle its paired solid bridge. A woven bridge also powers relay gates for that attempt. |
| Grapple / release | F | B | Attach to the highlighted, visible round socket above the courier within 240px. Steer to swing. Press again to detach, or jump for an upward release. A solid obstruction breaks the tether. |
| Rewind | Hold Shift | Hold LB | Follow up to six seconds of the actual laid trail at three recorded samples per physics tick. Release to resume control. Time and hazards continue. Solid geometry can stop the rewind; hazards can still kill. |

All three keyboard actions can be remapped in Settings → Controls → Thread. HUD prompts follow actual bindings and the last meaningful keyboard/controller input. The rewind meter reports stored history, not an invented energy resource. Reduced effects retain functional thread paths and hazard information.

## Teaching missions

41. **A stitch across** — weave a bridge across an otherwise unjumpable gap.
42. **Swing the signal** — attach, steer and jump-release across a pit.
43. **A living circuit** — keep a relay gate powered with a stitch.
44. **Follow it home** — reach the white relay and rewind to the exit.
45. **The unbroken thread** — combine bridge, relay checkpoint, rewind and a grapple crossing in a scrolling course.

These five missions are accessible through **Thread lessons** on the main menu. Later lessons unlock in order. Optional gold fragments remain separate from mandatory white relay checkpoints. Every original room also has authored sockets and bridge/relay terminals; its original route remains playable without tools.

## Implementation boundaries

ThreadTool owns bounded history, bridge state, anchor selection and drawing. CharacterBody2D performs swing constraints, jump release and collision-respecting rewind movement. LevelRoot owns authored sockets, stitch pairs, checkpoints, gate evaluation and exit goals. RunController continues to own time, death, pause and completion. Resets clear thread state in place without accumulating nodes. The old movement values are unchanged when the thread tool is inactive.

Save layout revision 3 retains stable IDs, unlocks, fragments and settings; earlier-layout times are archived so new routes do not compete with old physics/tool conditions. New default actions preserve a legacy remap that already used E or F by choosing a spare default key for the new action.

## Rewind recovery and interaction feedback

Holding an empty or obstructed trail no longer suspends the courier. Normal gravity and collision movement continue; release Rewind to start recording a fresh trail, then press it again to return. The HUD reports the release requirement. This uses the same shared movement resource in every room.

Reachable stitch pairs gain a paper outline, using the exact reach and line-of-sight rules of the stitch action. Nearby and tethered prompts follow current bindings, and lesson hints advance with the real objective state. The browser touch controls expose these same states.
