# Threadrunner

## Platform

Godot 4.7.2 game for Windows x64 and browsers. Logical viewport 640 × 360; default native window 1280 × 720. The browser edition runs as single-threaded WebAssembly on GitHub Pages, with responsive touch controls and browser-local saves. Players do not need accounts.

## Product Purpose

A precision platformer about a courier carrying a signal through an abandoned electric foundry. The user selected the second displayed design, recorded in docs/design/electric_foundry_reference.png: tactile black and charcoal industrial materials, electric blue thread, violet and pink danger, and amber heat. The usable thread stitches bridges and relays, grapples and swings, and rewinds along the laid trail.

## Capabilities and Constraints

Forty original campaign rooms plus five Threadwork teaching missions. The first thirty campaign rooms and first four lessons are single-screen; Afterlight and the combined lesson scroll horizontally. Running, variable jumps, wall slides and wall jumps remain in CharacterBody2D with one shared MovementConfig. Thread physics use that same shared resource. Room geometry and anchor positions are authored scene data. Preserve stable room IDs, optional fragments, local progress and fast retries.

Keyboard, controller and browser touch input, keyboard remapping, audio settings, fullscreen, reduced decorative effects and adjustable stick deadzone. Thread lessons are available directly from the main menu. The gameplay canvas shows only a pause icon and a small bottom-left rewind-history rail. Instructions and the current lesson objective live in Pause → How to play; the browser uses a responsive help panel. Physical-controller feel and subjective listening remain human playtest tasks.

The visual replacement preserves the original courier, all forty-five stable room IDs, authored room geometry, CharacterBody2D movement, shared MovementConfig and save schema. Visual materials and atmosphere do not define collision bounds.

## Brand Commitments

Threadrunner; the original warm-white courier, electric blue scarf/thread/exits, violet saws, pink barriers and spikes, amber heat and gold diamond fragments. Spike triangles, toothed saws, square stitch terminals, round grapple sockets and crossed gate strands supplement color. Dark industrial material texture and atmospheric depth support the route; sharp landing edges and hazard cores remain readable. The thread is a tool and the identity's continuous visual motif.

## Evidence on Hand

Canonical executable checks: tools/qa.py; actual outcomes belong in docs/qa_report.md. The approved Electric Foundry reference is docs/design/electric_foundry_reference.png. Exact generated-asset prompts, dimensions and hashes, plus the pinned Godot MIT pause-icon source, are recorded in docs/foundry_asset_provenance.json. DESIGN.md and docs/art_direction.md describe the replacement world; the earlier teal/coral direction in docs/visual_research.md is historical. The user explicitly requested the public GitHub repository and GitHub Pages browser release; deployment uses that existing repository.
