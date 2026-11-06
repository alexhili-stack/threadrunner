---
name: Threadrunner
description: Carry the last signal.
colors:
  ink: "#08090b"
  paper: "#f2f3e9"
  secondary: "#afb3bb"
  thread: "#008cff"
  text-accent: "#299dff"
  rule: "#35383e"
  danger: "#ff3aba"
  saw: "#b68aff"
  heat: "#ffae42"
  fragment: "#f5cc83"
  platform: "#303237"
  landing-edge: "#c6c9cf"
  selected-surface: "#202c3d"
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
  browser-body:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: 550
    lineHeight: 1.6
  browser-help:
    fontFamily: Manrope
    fontSize: 16px
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
    width: 72px
    height: 2px
  rewind-fill:
    backgroundColor: "{colors.thread}"
    height: 2px
  pause-button:
    width: 24px
    height: 30px
    rounded: "{rounded.control}"
---

# Design System: Threadrunner

## Overview

**Creative North Star: "Electric Foundry"**

Carry the last signal through a tactile, almost-black industrial foundry. Worn charcoal concrete and metal, layered machinery and a few amber lamps create depth behind the original warm-white courier. A continuous electric blue scarf and thread ties the identity to its working tools. Violet saws and pink barriers and spikes carry concentrated danger color.

The user approved the second displayed design, preserved in docs/design/electric_foundry_reference.png. It replaces the earlier teal/coral vector-only direction. The implementation combines generated environment, material and haze textures with native Godot silhouettes, collision geometry and interface controls. Exact asset prompts and provenance live in docs/foundry_asset_provenance.json.

**Key Characteristics:**

- Tactile black, charcoal and gray industrial layers behind crisp playable geometry.
- A continuous electric blue thread shared by identity and functional tools.
- Violet, pink and amber hazard accents with distinct silhouettes.
- A gameplay canvas with only a pause icon and a small history rail.

## Colors

ThreadStyle and the selected-control overrides are the executable palette; the frontmatter records their reusable colors. The browser shell shares the same ink, paper, secondary, thread and rule values.

### Primary

Electric blue belongs to the scarf, real rewind trail, woven bridge, grapple tether, available exit, powered gate, interactive focus and primary actions. An unmet lesson exit stays secondary gray until its goal is met. No objective label appears over the exit.

### Secondary

Pink identifies spike triangles, closed crossed-strand barriers and their haze. Violet identifies toothed saw outlines and saw haze. Amber heat identifies active vents and warm industrial lighting; gold remains the fragment color and the warning state before timed hazards change. Powered gates remain blue and do not show a timed closing warning.

### Neutral

Near-black ink, charcoal platform faces, gray secondary text and quiet rules support warm-white courier and UI text. Pale gray landing edges remain distinct from textured platform faces and distant machinery. The generated background stays dark and predominantly neutral.

## Typography

Retain the self-hosted Barlow Condensed SemiBold and Manrope fonts with their SIL OFL notices. Manrope uses an actual 550-weight OpenType variation with an integer axis tag in Godot. Native display sizes are 76 for the opening title, 44 for overlays, 34 for page headings and 20–26 for menu room titles. Normal controls use Manrope at 12–15 logical pixels; menu metadata uses smaller local sizes. Completion records retain condensed numerals. Active gameplay has no title, timer, instructions or status text.

The browser uses the same font files: Manrope for controls and help copy, with Barlow Condensed for boot and help headings. The browser help title is 40px, reducing to 34px on narrow screens; its body copy remains readable at 16px.

## Layout

Work on the 640 × 360 logical canvas, scaled by Godot. The gameplay HUD contains only the pause icon at the upper right and the history rail at the lower left. The rail sits at logical position (16, 345); the pause button sits at (603, 9). Do not add gameplay timers, room titles, hints, objectives, instruction strips or control bars over the playfield.

Menus retain 24–33px outer margins, forty campaign rooms plus five lessons, five chapter tabs, numbered tiles and aspect-preserving previews. Settings separate Sound, Controls and Display; Controls has Movement and Thread groups. Pause → How to play holds bindings, tool explanations and the current room objective. Keep full keyboard focus paths.

The browser player fills the viewport. Browser navigation is hidden during boot and gameplay. Help appears only in its dedicated, scrollable help panel, with responsive padding and readable line lengths; it does not become a persistent header or footer. Functional touch inputs sit outside the game canvas. On portrait phones up to 620px wide, the full 16:9 arena and its touch inputs form one vertically centered group, with thread tools in a second input row. Help and input layout adapt without changing the logical game canvas.

## Elevation & Depth

Depth comes from the generated dark foundry plate, low-contrast material grain and machinery behind sharp gameplay surfaces. The background has a small horizontal pan in scrolling rooms and receives a dark wash in menus. Platform faces use the repeated charcoal surface texture; pale top edges define actual landings.

Soft electric haze is intentionally part of this world. It sits behind sharp hazard cores: pink around spike tips and closed barriers, violet around saws, amber at active vents. The haze breathes gently rather than flashing. Reduced effects removes this atmospheric layer while retaining hazards and functional thread paths. Pause and completion use a near-black veil rather than UI drop shadows.

## Shapes

Keep the original courier silhouette and short flowing scarf. Square terminals weave bridges; round sockets attach grapples. The continuous fading trail is actual rewind history. Gold diamond fragments stay separate from taller rectangular relay checkpoints. Exits use a bracketed doorway and woven knot. Spike triangles, rotating teeth and crossed gate strands supplement color. Material texture and haze do not change the authored collision silhouette or imply new walkable geometry. Interface controls keep square corners.

## Components

Native primary actions use electric blue fill and ink text, paper fill on hover and pale blue when pressed. Their one-pixel focus outline is paper. Secondary buttons use a quiet bottom rule, a charcoal hover fill and a complete one-pixel blue focus outline. Disabled controls use muted text and a darker fill. Controls change states immediately. Sliders use a blue filled rail, paper highlighted fill and an authored blue diamond knot handle. Toggle buttons state On or Off. Selected chapter/settings tabs use a blue-charcoal fill with a blue label; selected Movement/Thread groups use the blue label.

The history meter is a custom flat rail at the lower left, with its dimensions recorded in the frontmatter. Blue fill reports stored position history. It has no seconds label, percentage text, border or rounded end cap. The trail records up to six seconds of the courier's actual route. The pause control uses the pinned Godot MIT Pause.svg icon and has no visible text label. Its tooltip identifies Pause and the current binding.

How to play contains the movement and thread bindings, explanations of stitch/grapple/rewind and the current lesson objective. The browser help panel mirrors that information outside active play and includes browser-save context. Browser utility buttons use the same blue focus color with a two-pixel ring; the game keeps its native one-pixel focus treatment.

## Do's and Don'ts

### Do:

- Do keep the courier, landing edges, dangerous silhouettes and thread states readable first.
- Do keep active gameplay to the pause icon and bottom-left history rail.
- Do place instructions and room objectives in How to play.
- Do keep material and haze behind sharp collision and hazard silhouettes.
- Do preserve functional tool paths when reduced effects are enabled.
- Do keep motion bounded and retry effects brief.

### Don't:

- Don't replace actionable shapes with decoration or imply inactive dotted bridges are solid.
- Don't add busy grids behind UI text or hide focus.
- Don't add timers, titles, hints, objectives, instruction bars or browser headers and footers during play.
- Don't copy reference-game assets.


Selected and pressed small native text uses #299dff for contrast on charcoal. Functional thread geometry remains #008cff. Native help has an opaque black field with separated objective copy; browser help focuses Back to pause when opened.
