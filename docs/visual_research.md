# Visual research and implementation brief — 6 November 2026

The user requested research into strong platformers and minimalist presentation. These are reference studies, not a ranking or an instruction to copy artwork.

| Primary source inspected | Observation / interpretation | Threadrunner application |
|---|---|---|
| [N++ official site](https://nplusplus.org/) and [official screenshot gallery](https://nplusplus.org/media/) | The developer explicitly describes minimalist graphics/UI; screenshots separate geometry and interactive objects with restrained vector shapes. | Quiet backgrounds, consistent silhouettes, compact navigation, brighter collision edges. |
| [Celeste official site](https://www.celestegame.com/) and [official screenshot](https://www.celestegame.com/images/screenshots/00.png) | My visual interpretation: a memorable character and strong foreground edges carry identity despite a small on-screen character. | Keep the white courier and distinctive scarf; enlarge their actual visual grammar on the title screen. |
| [Dustforce official image gallery](https://dustforce.com/images) | My visual interpretation: motion traces and quieter distant forms distinguish movement from scenery. | Make the trailing thread readable, bounded and functional; reduce repeated facility marks. |

Official pages and actual browser screenshots were inspected. No reference artwork, level geometry, audio or branding was imported into the game. The separately sourced Barlow Condensed and Manrope fonts come from the official Google Fonts repository under SIL OFL 1.1.

## Direction contract

THESIS: Carry the last signal; the thread behind the courier is both the recognizable mark and a working platforming tool.

OWN-WORLD: Preserve the established warm-white courier, teal thread, coral danger and gold fragments. Use ink #09171e, paper #f2f3e9, secondary #a2b8bd, thread #58e1c3, coral #ff8175 and gold #f5cc83. Barlow Condensed headlines and Manrope 550-weight controls. Native Godot vector geometry, with no faux physical surfaces or raster scene imitations.

STORY: Begin or continue the run; learn the thread directly from the main menu; browse chapter routes; tune controls without losing progress. Each room teaches a route, while Threadwork explicitly teaches bridge, swing, relay, rewind and combination.

FIRST VIEWPORT: Large two-line Threadrunner lettering is divided by a teal thread. A larger courier with flowing scarf occupies the right field. The primary start action and Thread lessons entry are immediately visible. Progress stays quiet at the lower right.

FORM: A continuous line unifies scarf, laid trail, bridge, tether and exit knot. Shape-based terminals and hazards stay distinct. Use actual rendered views at 640 × 360 and 1280 × 720; test keyboard and synthetic controller input. Implement directly in the established native game and critique actual renders; there is no approved raster comp or web detector.

## Review boundary

Review menu, chapter selection, all settings groups, HUD, pause, completion, credits and active thread-tool views. Inspect text/spacing, contrast, focus states and foreground/background separation. Verify behavior separately through tools/qa.py. Human enjoyment, physical-controller feel and listening are not inferred from screenshots or synthetic events.
