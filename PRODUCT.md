# Threadrunner

## Platform

Godot 4.7.2 game for Windows x64 and browsers. Logical viewport 640 × 360; default native window 1280 × 720. The browser edition runs as single-threaded WebAssembly on GitHub Pages, with responsive touch controls and browser-local saves. Players do not need accounts.

## Product Purpose

A precision platformer about a courier carrying a signal through an abandoned transit facility. The user requested a refined minimalist interface and a usable thread: stitching bridges and relays, grappling and swinging, and rewinding along the laid trail.

## Capabilities and Constraints

Forty original campaign rooms plus five Threadwork teaching missions. The first thirty campaign rooms and first four lessons are single-screen; Afterlight and the combined lesson scroll horizontally. Running, variable jumps, wall slides and wall jumps remain in CharacterBody2D with one shared MovementConfig. Thread physics use that same shared resource. Room geometry and anchor positions are authored scene data. Preserve stable room IDs, optional fragments, local progress and fast retries.

Keyboard and controller play, keyboard remapping, audio settings, fullscreen, reduced decorative effects and adjustable stick deadzone. Thread lessons are available directly from the main menu. Physical-controller feel and subjective listening remain human playtest tasks.

## Brand Commitments

Threadrunner; a warm-white courier, teal scarf/thread/exits, coral danger, gold diamond fragments. Spike triangles, toothed saws and crosshatched lethal gates supplement color. The thread is a tool and the identity's continuous visual motif.

## Evidence on Hand

Canonical executable checks: tools/qa.py. Current acceptance evidence is recorded in docs/qa_report.md and docs/visual_acceptance_report.md. Reference research and interpretation are in docs/visual_research.md. The user explicitly requested the public GitHub repository and GitHub Pages browser release; deployment uses that existing repository.
