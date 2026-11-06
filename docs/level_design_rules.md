# Level rules

Four chapters each have ten separately authored scenes. Preserve stable IDs. Use shared physics and a safe starting floor. Keep the exit and diamond in bounds. Required hazards must be readable within the current camera view and have safe observation space. Crosshatched gates are lethal while closed and show a cycle bar; empty teal gates are open. Saws have moving toothed outlines; spikes are triangles. Optional fragments never block ordinary exits.

LevelRoot arrays are authored scene geometry; tools/create_content.py contains the initial authoring data, not a runtime procedural generator. Scene files are the canonical finished geometry. Do not rerun initial authoring over later scene edits. tools/route_runner.gd records actual fixed-step controller inputs and replays each successful fragment-plus-exit sequence three times. Gate waiting uses the live cycle. Fixtures do not change collisions, hazards, movement or grant fragments.

The route solver is evidence tooling, not gameplay AI or a proof of human fairness. Short clear times and recurring room motifs need human review. Revalidate fixtures after editing geometry or movement.

Version 1.1 adds multi-pass routes and ten 1280x360 scrolling rooms. Required wall routes must emit real wall-jump events; variable-jump routes must include an early release. The hold-right/no-jump negative fixture must fail to clear every room. Preserve recovery rooms and optional fragments.

Version 1.2 retains those 40 original stable IDs and geometry, adding scene-authored thread anchors and stitch pairs. Five Threadwork teaching scenes form a fifth chapter, for 45 rooms total. Mandatory white relay checkpoints are separate from optional gold fragments. Thread lessons have explicit tool exit goals. tools/thread_routes.gd records six-input routes and replays each three times through the real controller; tools/route_runner.gd retains the 40 original ordinary/fragment regressions.
