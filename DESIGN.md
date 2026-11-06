---
name: Threadrunner
description: Carry the last signal.
colors:
  ink: "#09171e"
  paper: "#f2f3e9"
  secondary: "#a2b8bd"
  thread: "#58e1c3"
  rule: "#304851"
  danger: "#ff8175"
  fragment: "#f5cc83"
  platform: "#1b343d"
  landing-edge: "#b9cecc"
typography:
  display:
    fontFamily: Barlow Condensed
    fontSize: 76px
    fontWeight: 600
  heading:
    fontFamily: Barlow Condensed
    fontSize: 34px
    fontWeight: 600
  body:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: 550
  metadata:
    fontFamily: Manrope
    fontSize: 9px
    fontWeight: 550
spacing:
  small: 8px
  medium: 16px
  screen-margin: 24px
rounded:
  control: 0px
components:
  primary-button:
    backgroundColor: "{colors.thread}"
    textColor: "{colors.ink}"
    height: 30px
    rounded: "{rounded.control}"
    padding: 3px 10px
  secondary-button:
    textColor: "{colors.paper}"
    height: 30px
    rounded: "{rounded.control}"
    padding: 3px 10px
  rewind-rail:
    backgroundColor: "{colors.rule}"
    width: 140px
    height: 2px
  rewind-fill:
    backgroundColor: "{colors.thread}"
    height: 2px
---

# Design System: Threadrunner

## Overview

**Creative North Star: "Carry the last signal."**

The signal's thread connects the game identity to its mechanics. Use crisp native vector geometry and a quiet night-time facility. The opening screen pairs condensed lettering with the actual courier's visual grammar and one flowing teal scarf. Threadwork reuses the same visual world rather than introducing another style.

This records the implemented native Godot system. The project has no approved raster comp, FORM seed or QUALITY BAR card.

**Key Characteristics:**

- Native vector geometry with quiet architectural depth.
- A continuous teal thread shared by identity and functional tools.
- Distinct silhouettes for the courier, hazards, terminals and fragments.

## Colors

ThreadStyle is the executable palette. Warm white identifies the courier and UI hierarchy. Teal belongs to threads, available exits, powered gates and focus. An unmet lesson exit uses secondary text color and a tool objective label; it turns teal when its objective is met. Coral belongs to danger; gold belongs to collectible diamonds and timed gate warnings. A powered gate stays teal rather than showing a closing warning. Secondary text is blue-tinted and sufficiently distinct from the dark field. Gameplay chapter backgrounds shift gently through teal, warm mechanisms, violet night and Afterlight; menus return to quiet ink. No decorative saturated scenery competes with hazards.

## Typography

Self-host Barlow Condensed SemiBold and Manrope, with their SIL OFL notices. Manrope uses an actual 550-weight OpenType variation with an integer axis tag in Godot. Display sizes are 76 for the title, 44 for overlays, 34 for page headings, 22–26 for room titles and 12–15 for normal controls. Timers use condensed numerals. Gameplay hints and footer prompts use 8–9 logical pixels and are inspected at the minimum window size.

## Layout

Work on the 640 × 360 logical canvas, scaled by Godot. Menus use 24–33px outer margins. Protect the room's action space: HUD information stays above its geometry. Ordinary campaign rooms place control prompts in the bottom strip; Threadwork lessons place them above the playfield so bottom pit hazards remain exposed. Room selection presents forty campaign rooms and five lessons through five chapter tabs, large numbered tiles, and an aspect-preserving scene preview. Settings separate Sound, Controls and Display; Controls has Movement and Thread groups. Keep full keyboard focus paths.

## Elevation & Depth

Depth comes from restrained value separation, not glows or heavy shadows. Pause and completion dim the room while retaining its silhouette. Platform tops are the brightest geometry edges; background architecture stays substantially quieter. Avoid repeated hatching on ordinary surfaces.

## Shapes

Square terminals weave bridges. Round sockets attach grapples. A continuous fading trail is the actual rewind history; the scarf is a short, flowing ribbon. Diamond fragments remain gold. Relays use a taller rectangular beacon with a central stroke. Exits use a bracketed doorway and woven knot. Spikes, teeth and crossed gate strands remain recognizably dangerous independently of color.

## Components

Primary actions use teal fill and ink text, paper fill on hover and a pale teal pressed state. Their focus outline is paper. Secondary buttons use a bottom rule, a platform-toned hover fill and a complete one-pixel teal focus outline. Disabled controls use muted text and a darker fill. Controls have square corners and immediate state changes. Sliders use a teal filled rail, a paper highlighted fill and an authored diamond knot handle. Toggle buttons state On or Off. Chapter tabs and control groups retain a visible selected state.

The rewind meter is a custom flat rail at the upper right, with the dimensions recorded in the frontmatter. Its teal fill reports stored position history and is paired with a seconds label; it is not an energy resource. It has no percentage text, border or rounded end cap. The trail records up to six seconds of the courier's actual route. Functional thread paths, woven bridges and grapple tethers stay available with reduced effects; decorative movement, scarf trails and pulses are reduced. Control prompts follow the current bindings and last meaningful keyboard or controller input.

## Do's and Don'ts

### Do:

- Do keep the courier, landing edges, dangerous silhouettes and thread states readable first.
- Do use the same vocabulary in the HUD, lessons and settings.
- Do preserve functional tool paths when reduced effects are enabled.
- Do keep motion bounded and retry effects brief.

### Don't:

- Don't replace actionable shapes with decoration or imply inactive dotted bridges are solid.
- Don't add busy grids behind UI text or hide focus.
- Don't cover lesson pit hazards with a bottom prompt strip.
- Don't copy reference-game assets.
