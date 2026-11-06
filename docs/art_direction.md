# Art and feedback

## Approved Electric Foundry world

The user chose the second displayed design, preserved in [electric_foundry_reference.png](design/electric_foundry_reference.png). This approval replaces the earlier teal/coral vector-only direction, including the former chapter background palettes. Keep the original warm-white courier and the working thread. Build the world from tactile almost-black, charcoal and gray concrete/metal; electric blue thread and exits; violet saws; pink barriers and spikes; amber heat; and gold diamond fragments. DESIGN.md frontmatter records the executable ThreadStyle palette.

## Materials, depth and effects

The background plate contains dark foundry machinery, distant structural layers and sparse warm lamps. It stays behind the action and pans slightly in scrolling rooms; a dark wash quiets it in menus. Platform faces use a repeated charcoal surface texture beneath pale, sharply drawn landing edges. The reference establishes materials and atmosphere, not replacement room geometry.

HazardAtmosphere draws the neutral electric haze texture behind native hazard cores, tinted pink at spikes and closed barriers, violet at saws and amber at active vents. Its slow breathing is decorative. Reduced effects removes haze and reduces decorative feedback while preserving hazard silhouettes, functional thread history, woven bridges and tethers. Avoid flashing and effects that obscure landings.

Vents retain neutral safe slits and gold warning dots, then show amber active plumes. Open gates and relay-powered gates are blue; an unpowered timed gate warns gold before closing; closed gates are pink with crossed strands. Unmet lesson exits stay secondary gray without objective text over the doorway. Square stitch terminals, round grapple sockets, triangular spikes, toothed saws, bracketed exits and diamond fragments remain distinct independently of color.

## Interface and help

The active 640 × 360 gameplay canvas contains only an icon-only pause button at the upper right and a 72 × 2 logical-pixel history rail at the bottom left. No timer, room title, hints, instructions, objective labels, control bar or browser header/footer appears over play. The history rail has blue proportional fill and no text label. Instructions, current bindings and lesson objectives live in Pause → How to play, on an opaque black field. Small selected and pressed native text uses #299dff; functional thread blue stays #008cff. Browser help uses a dedicated responsive, scrollable panel; utility navigation is hidden during gameplay. Functional phone controls stay outside the arena; portrait phones up to 620px center the full 16:9 stage and touch inputs together, with thread tools in a second input row.

Retain licensed Barlow Condensed SemiBold and Manrope, including the actual Manrope 550-weight variation. Menus retain chapter tabs, room previews and grouped Sound/Controls/Display settings with Movement/Thread control groups. Blue and paper focus treatments remain visible. The pause button uses the pinned Godot 4.7.2 MIT Pause.svg; its source URL and notice path are recorded in the provenance file.

## Asset provenance and behavior boundaries

Generated production assets are assets/art/foundry/background.png, platform_surface.png and electric_haze.png. [foundry_asset_provenance.json](foundry_asset_provenance.json) records their exact prompts, dimensions and SHA-256 entries, the selected reference and the pause-icon source. These are authored presentation layers; collision bodies, all forty-five stable room IDs, room geometry, movement configuration and save schema remain separate. The documentation pass does not itself establish runtime or visual acceptance.

PlayerVisuals independently depicts idle/run/jump/fall/wall slide. The courier remains behind pause/completion overlays; actual death draws the short radial burst. Jump/landing dust, scarf motion, collection rings and exit pulses use bounded drawings. Screen shake is brief and can be disabled; reduced effects suppresses it.

Original audio remains separate from the material replacement. Sounds cover jump, wall jump, landing, death, fragment, clear, menu and optional respawn. Eight reusable SFX players cap overlap; pause stops active effects. Four ambient chapter compositions crossfade through two reusable Music players. Audio settings and controller deadzone persist. Subjective sound quality requires listening.
